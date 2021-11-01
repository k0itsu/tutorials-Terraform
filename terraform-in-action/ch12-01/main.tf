resource "random_string" "rand" {
  length  = 24
  special = false
  upper   = false
}

locals {
  namespace = substr(join("-", [var.name, random_string.rand.result]), 0, 24)
}

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


## provision the two aws codebuild projects
locals {
  projects = ["plan", "apply"]
}

resource "aws_codebuild_project" "project" {
  count        = length(local.projects)
  name         = "${local.namespace}-${local.projects[count.index]}"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "hashicorp/terraform:${var.terraform_version}"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/templates/buildspec_${local.projects[count.index]}.yml")
  }
}