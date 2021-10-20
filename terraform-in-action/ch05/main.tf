resource "azurerm_resource_group" "default" {
  name     = local.namespace
  location = var.location
}

resource "random_string" "rand" {
  length  = 24
  special = false
  upper   = false
}

locals {
  namespace = substr(join("-", [var.namespace, random_string.rand.result]), 0, 24)
}