async function loadStory() {
  const container = document.getElementById("story");

  try {
    const res = await fetch(`stories/latest.json?t=${Date.now()}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const story = await res.json();

    const words = story.words
      .map(
        (w) => `<li><span class="fr">${w.french}</span> — <span class="en">${w.english}</span></li>`
      )
      .join("");

    container.innerHTML = `
      <div class="story-meta">
        <span>${story.date}</span>
        <span>${story.theme}</span>
        <span>${story.format}</span>
      </div>
      <h2 class="story-title">${story.title_fr}</h2>
      <p class="story-text">${story.text_fr}</p>
      <div class="glossary">
        <h2>Vocabulaire</h2>
        <ul>${words}</ul>
      </div>
    `;
  } catch (err) {
    container.innerHTML = `<p class="error">Impossible de charger le texte du jour. Revenez plus tard.</p>`;
    console.error(err);
  }
}

loadStory();
