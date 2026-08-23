locals {
  name_prefix = "${var.project_prefix}-${var.environment}"

  common_tags = {
    Project     = "mot-tisse"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "site" {
  source = "./modules/site"

  bucket_name = var.bucket_name
  tags        = local.common_tags
}

module "lambda" {
  source = "./modules/lambda"

  name_prefix = local.name_prefix
  tags        = local.common_tags

  bucket_name = module.site.bucket_name
  bucket_arn  = module.site.bucket_arn
  model_id    = var.bedrock_model_id
  aws_region  = var.aws_region
}

module "scheduler" {
  source = "./modules/scheduler"

  name_prefix = local.name_prefix
  tags        = local.common_tags

  lambda_function_name = module.lambda.function_name
  lambda_function_arn  = module.lambda.function_arn
  schedule_expression  = var.schedule_expression
}
