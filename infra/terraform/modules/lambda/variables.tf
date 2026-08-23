variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "bucket_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "model_id" {
  type = string
}

variable "aws_region" {
  type = string
}
