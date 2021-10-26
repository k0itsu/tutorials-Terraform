terraform {
  backend "s3" {
    bucket         = "bucket-name"
    key            = "jesse/james"
    region         = "us-east-1"
    encrypt        = true
    role_arn       = "amazon-arn"
    dynamodb_table = "dynamodb-table"
  }
  required_version = ">= 0.15"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}