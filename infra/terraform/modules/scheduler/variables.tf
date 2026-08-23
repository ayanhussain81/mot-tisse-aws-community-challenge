variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "lambda_function_name" {
  type = string
}

variable "lambda_function_arn" {
  type = string
}

variable "schedule_expression" {
  type = string
}
