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


# configuring environment variables
locals {
  # template for the backend configuration
  backend = templatefile("${path.module}/templates/backend.json",
    { config : var.s3_backend_config, name : local.namespace })
  
  # declare default environment variables
  default_environment = {
    # TF_IN_AUTOMATION - if set to a non-empty value, tf adjusts the output
    # to avoid suggesting specific commands to run next
    TF_IN_AUTOMATION  = "1"
    # TF_INPUT - if set to 0, disables prompts for variables that don't have values set
    TF_INPUT          = "0"
    # CONFIRM_DESTROY - if set to 1, codebuild will queue a destroy run instead of a create run
    CONFIRM_DESTROY   = "0"
    # WORKING_DIRECTORY - a relative path in which to execute tf.
    # defaults to the source code root directory.
    WORKING_DIRECTORY = var.working_directory
    # BACKEND - a json-encoded string that configures the remote backend.
    BACKEND           = local.backend,
  }

  # merge default environment variables with user-supplied values
  environment = jsonencode([for k, v in verge(local.default_environment, var.environment) : { name: k, value: v, type : "PLAINTEXT"}])
}

