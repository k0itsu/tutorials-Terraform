provider "aws" {
  region = "us-east-1"
}

module "s3backend" {
  # if we publish the example from ch06, we can point to it
  # source = "github.com/terraform-in-action/terraform-aws-s3backend"
  source    = "terraform-in-action/s3backend/aws"
  namespace = "team-rocket"
}

output "s3backend_config" {
  value = module.s3backend.config
}