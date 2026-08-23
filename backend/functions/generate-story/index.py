import json
import os
import random
from datetime import datetime, timezone

import boto3

BUCKET_NAME = os.environ["BUCKET_NAME"]
MODEL_ID = os.environ["MODEL_ID"]
HISTORY_KEY = "state/history.json"
HISTORY_MAX_WORDS = 150  # rolling window before old words become fair game again

s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")

THEMES = [
    "le café", "la météo", "les animaux", "la famille", "les courses",
    "le week-end", "le marché", "la plage", "la cuisine", "un anniversaire",
    "le sport", "les vacances", "la ville", "l'école", "la musique",
    "un pique-nique", "la nature", "le médecin", "les transports", "la maison",
    "le jardin", "les couleurs", "les saisons", "l'aéroport", "le restaurant",
]

FORMATS = ["histoire courte", "poème"]

SYSTEM_PROMPT = """Tu es un professeur de français qui prépare le contenu quotidien \
d'une application pour un(e) apprenant(e) anglophone de niveau A1 (grand débutant).

Réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, au format exact :
{
  "title_fr": "titre court en français",
  "words": [
    {"french": "mot", "english": "meaning"},
    ... (exactement 6 mots)
  ],
  "text_fr": "le texte complet en français"
}

Règles :
- Les 6 mots doivent être nouveaux, utiles et adaptés au niveau A1 (vocabulaire concret \
et fréquent), en lien avec le thème donné.
- Le texte doit utiliser naturellement les 6 mots, rester au niveau A1 (phrases simples, \
présent de l'indicatif principalement), et faire environ 80 à 120 mots.
- Si le format demandé est "poème", structure le texte en courtes lignes séparées par \
des sauts de ligne (\\n).
- N'utilise aucun des mots déjà vus listés ci-dessous.
"""


def _load_history() -> list[str]:
    try:
        obj = s3.get_object(Bucket=BUCKET_NAME, Key=HISTORY_KEY)
        return json.loads(obj["Body"].read())["words"]
    except s3.exceptions.NoSuchKey:
        return []


def _save_history(words: list[str]) -> None:
    trimmed = words[-HISTORY_MAX_WORDS:]
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=HISTORY_KEY,
        Body=json.dumps({"words": trimmed}, ensure_ascii=False).encode("utf-8"),
        ContentType="application/json",
    )


def _generate(theme: str, fmt: str, seen_words: list[str]) -> dict:
    user_prompt = (
        f"Thème : {theme}\n"
        f"Format : {fmt}\n"
        f"Mots déjà vus (à éviter) : {', '.join(seen_words) if seen_words else '(aucun)'}"
    )

    response = bedrock.converse(
        modelId=MODEL_ID,
        system=[{"text": SYSTEM_PROMPT}],
        messages=[{"role": "user", "content": [{"text": user_prompt}]}],
        inferenceConfig={"temperature": 0.9, "maxTokens": 800},
    )

    raw = response["output"]["message"]["content"][0]["text"].strip()
    if raw.startswith("```"):
        raw = raw.strip("`")
        raw = raw[raw.find("{"):raw.rfind("}") + 1]

    data = json.loads(raw)
    if not data.get("words") or not data.get("text_fr"):
        raise ValueError(f"Malformed model output: {raw[:200]}")
    return data


def handler(event, context):
    seen_words = _load_history()
    theme = random.choice(THEMES)
    fmt = random.choice(FORMATS)

    story = _generate(theme, fmt, seen_words)

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    payload = {
        "date": today,
        "theme": theme,
        "format": fmt,
        "title_fr": story["title_fr"],
        "text_fr": story["text_fr"],
        "words": story["words"],
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }

    body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
    s3.put_object(Bucket=BUCKET_NAME, Key=f"stories/{today}.json", Body=body, ContentType="application/json")
    s3.put_object(Bucket=BUCKET_NAME, Key="stories/latest.json", Body=body, ContentType="application/json")

    _save_history(seen_words + [w["french"] for w in story["words"]])

    return {"statusCode": 200, "body": json.dumps({"date": today, "theme": theme})}
