terraform {
  backend "s3" {
    bucket         = "cool-unique-interesting-bucket-name"
    key            = "team1/my-cool-project"
    region         = "us-east-1"
    encrypt        = true
    role_arn       = "arn:aws:iam::arns-yo"
    dynamodb_table = "dynamodb-table-name"
  }
  required_version = ">= 0.15"
}

variable "region" {
  description = "AWS Region"
  type        = string
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name = terraform.workspace
  }
}