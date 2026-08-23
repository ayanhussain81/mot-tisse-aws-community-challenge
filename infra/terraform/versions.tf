terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Local state is fine for solo development — it's what this defaults to.
  # Before more than one person touches this repo, switch to a remote
  # backend so state isn't sitting on one laptop.
}

provider "aws" {
  region = var.aws_region
}
