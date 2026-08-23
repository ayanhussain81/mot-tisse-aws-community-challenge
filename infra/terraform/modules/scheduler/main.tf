# EventBridge Scheduler calls the Lambda InvokeFunction API directly using
# this role's credentials — unlike classic EventBridge Rules, no separate
# Lambda resource-based permission is needed.
resource "aws_iam_role" "scheduler_invoke" {
  name = "${var.name_prefix}-scheduler-invoke"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "invoke_lambda" {
  name = "${var.name_prefix}-invoke-lambda"
  role = aws_iam_role.scheduler_invoke.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = var.lambda_function_arn
    }]
  })
}

resource "aws_scheduler_schedule" "daily" {
  name = "${var.name_prefix}-daily"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule_expression

  target {
    arn      = var.lambda_function_arn
    role_arn = aws_iam_role.scheduler_invoke.arn
  }
}
