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
# storage account provides metadata about where the data will be stored
# and how much redundancy/data replication you want
resource "azurerm_storage_account" "storage_account" {
  name                     = random_string.rand.result
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# storage container for azure - to store application source code and documents in a nosql db
resource "azurerm_storage_container" "storage_container" {
  name                  = "serverless"
  storage_acccount_name = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

# step 3 of 4 - storage blob
# this is where we insert the application code
# the example uses a terraform module 'shim' to get the application code
module "ballroom" {
  source = "terraform-in-action/ballroom/azure"
}

resource "azurerm_storage_blob" "storage_blob" {
  name                   = "server.zip"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container.name
  type                   = "Block"
  source                 = module.ballroom.output_path
}

# step 4 of 4 - function app
# use a data source to produce a shared access signature (SAS) token 
# to be able to download the application source code from the storage blob
data "azurerm_storage_account_sas" "storage_sas" {
  connection_string = azurerm_storage_account.storage_account.primary_connection_string

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob      = true
    queue     = false
    table     = false
    file      = false
  }

  start       = "2021-10-20T00:00:00Z"
  expiry      = "2022-10-20T00:00:00Z"

  permissions {
    read      = true
    write     = false
    delete    = false
    list      = false
    add       = false
    create    = false
    update    = false
    process   = false
  }
}