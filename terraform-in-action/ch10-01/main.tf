terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.28"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  profile = "<profile>"
  region  = "us-east-1"
}

resource "local_file" "credentials" {
  filename           = "credentials"
  file_permission    = "0644"
  sensitive_content  = <<-EOF
    [${aws_iam_user.app1.name}]
    aws_access_key_id = ${aws_iam_access_key.app1.id}
    aws_secret_access_key = ${aws_iam_access_key.app1.secret}

    [${aws_iam_user.app2.name}]
    aws_access_key_id = ${aws_iam_access_key.app2.id}
    aws_secret_access_key = ${aws_iam_access_key.app2.secret}
  EOF
}