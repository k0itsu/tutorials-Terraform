provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = "cosmic-howl-330222"
  region  = "us-east1"
}

provider "docker" {}