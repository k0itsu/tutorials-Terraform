terraform {
  required_version = ">= 0.15"
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4"
    }
  }
}

provider "nomad" {
  address = "<aws.address.nomad_ui>"
  alias   = "aws"
}

provider "nomad" {
  address = "<azure.address.nomad_ui>"
  alias   = "azure"
}

module "mmorpg" {
  source   = "terraform-in-action/mmorpg/nomad"
  fabio_db = "<azure.address.fabio_db>"
  fabio_lb = "<aws.address.fabio_lb>"

  providers = {
    nomad.aws   = nomad.aws
    nomad.azure = nomad.azure
  }
}

output "browserquest_address" {
  value = module.mmorpg.browserquest_address
}