data "archive_file" "generate_story" {
  type        = "zip"
  source_dir  = "${path.module}/../../../../backend/functions/generate-story"
  output_path = "${path.module}/build/generate-story.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "bucket_access" {
  name = "${var.name_prefix}-bucket-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${var.bucket_arn}/*"]
      },
      {
        # Without ListBucket, S3 masks a missing object as 403 AccessDenied
        # instead of 404/NoSuchKey — breaks the "no history yet" first-run path.
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [var.bucket_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_access" {
  name = "${var.name_prefix}-bedrock-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = ["arn:aws:bedrock:${var.aws_region}::foundation-model/${var.model_id}"]
    }]
  })
}

resource "aws_lambda_function" "generate_story" {
  function_name = "${var.name_prefix}-generate-story"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  # Bedrock generation can take a while — give it headroom beyond the 3s default.
  timeout     = 60
  memory_size = 256

  filename         = data.archive_file.generate_story.output_path
  source_code_hash = data.archive_file.generate_story.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      MODEL_ID    = var.model_id
    }
  }

  tags = var.tags
}
