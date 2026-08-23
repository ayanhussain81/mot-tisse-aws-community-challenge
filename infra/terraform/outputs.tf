output "website_url" {
  description = "Open this to see today's story"
  value       = "http://${module.site.bucket_name}.s3-website-${var.aws_region}.amazonaws.com"
}

output "bucket_name" {
  value = module.site.bucket_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "schedule_name" {
  value = module.scheduler.schedule_name
}
