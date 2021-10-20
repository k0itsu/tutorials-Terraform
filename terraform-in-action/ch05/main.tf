# step 1 of 4 - resource groups
# resource groups are similar to tags in AWS
# azure requires them to make it easier to keep track of resources
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

# step 2 of 4 -
# storage container for azure - to store application source code and documents in a nosql db
resource "azurerm_storage_account" "storage_account" {
  name                     = random_string.rand.result
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "serverless"
  storage_acccount_name = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

