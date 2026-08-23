variable "aws_region" {
  description = "AWS region to deploy into. Nova models are available here."
  type        = string
  default     = "us-east-1"
}

variable "project_prefix" {
  description = "Prefix applied to every resource name."
  type        = string
  default     = "mot-tisse"
}

variable "environment" {
  description = "Environment name — appended to resource names and applied as a tag"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name used for both the static site and the story/state JSON. Must be set in terraform.tfvars."
  type        = string
}

variable "bedrock_model_id" {
  description = "Bedrock model ID used to generate each day's story. Must have model access granted in the Bedrock console for this account/region first."
  type        = string
  default     = "amazon.nova-lite-v1:0"
}

variable "schedule_expression" {
  description = "EventBridge Scheduler cron expression (UTC) for the daily generation run."
  type        = string
  default     = "cron(0 13 * * ? *)" # 13:00 UTC daily
}
