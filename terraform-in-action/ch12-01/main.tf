# create a new Terraform workspace and declare the s3backend
# and codepipeline modules

variable "vcs_repo" {
  type = object({ identifier = string, branch = string })
}

provider "aws" {
  region = "us-east-1"
}

# codepipeline - gitops service
# similar to gcp cloud build or azure devops
# works as a ci/cd pipeline


## deploy s3 backend that will be used by codepipeline
module "s3backend" {
  source         = "terraform-in-action/s3backend/aws"
  principal_arns = [module.codepipeline.deployment_role_arn]
}

## deploy ci/cd pipeline for terraform
module "codepipeline" {
  source   = "./modules/codepipeline"
  name     = "terraform-in-action"
  vcs_repo = var.vcs_repo

  environment = {
    CONFIRM_DESTROY = 1
  }

  # deployment_policy file not created yet in first commit
  deployment_policy = file("./policies/helloworld.json")
  s3_backend_config = module.s3backend.config
}