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

# generate the presigned url
locals {
  package_url = "https://${azurerm_storage_account.storage_account.name}.blob.core.windows.net/${azurerm_storage_container.storage_container.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_sas.storage_sas.sas}"
}

resource "azurerm_app_service_plan" "plan" {
  name                = local.namespace
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  kind                = "functionapp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# azure_application_insights resource is required for instrumentation and logging
resource "azurerm_application_insights" "application_insights" {
  name                = local.namespace
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  application_type    = "web"
}

resource "azurerm_function_app" "function" {
  name                = local.namespace
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  https_only          = true

  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~2"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    WEBSITE_RUN_FROM_PACKAGE       = local.package_url
    WEBSITE_NODE_DEFAULT_VERSION   = "10.14.1"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.application_insights.instrumentation_key
    TABLES_CONNECTION_STRING       = data.azurerm_storage_account_sas.storage_sas.connection_string
    AzureWebJobsDisableHomepage    = true
  }
}