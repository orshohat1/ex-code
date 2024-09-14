locals {
  storage_account_prefix = "logs"
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###### MONGODB ###########
module "mongodb_atlas" {
  source       = "./modules/mongodb-atlas"
  public_key   = "cstwjbbw"
  private_key  = "d21a6d7a-d97e-494c-bc18-5132b8f06bd9"
  org_id       = "66d9e24ff21c98641e67ac73"
  project_name = "Project 1"
  cluster_name = "Cluster0"
}

###### VNET ###########
module "vnet" {
  source              = "./modules/virtual_network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  vnet_name           = "test-vnet"

  subnets = [
    {
      name             = var.appserivce_subnet_name
      address_prefixes = ["10.1.0.0/24"]
      delegation = {
        name = "web-app-delegation"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/action",
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    },
    {
      name             = var.pe_subnet_name
      address_prefixes = ["10.1.1.0/24"]
    }
  ]
}


###### STORAGE ACCOUNT ###########
# Generate randon name for storage account
resource "random_string" "storage_account_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = false
}

module "storage_account" {
  source              = "./modules/storage_account"
  name                = "${local.storage_account_prefix}${random_string.storage_account_suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_rules            = ["109.64.113.74"]

  virtual_network_subnet_ids = [
    module.vnet.subnet_ids[var.appserivce_subnet_name]
  ]
}


###### LOGS CONTAINER ###########
resource "azurerm_storage_container" "logs_container" {
  name                  = "logs"
  storage_account_name  = module.storage_account.name
  container_access_type = "private"

  depends_on = [
    module.storage_account
  ]
}

########### BLOB PRIVATE DNS ZONE & ENDPOINT #############################
module "blob_private_dns_zone" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
}

module "blob_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "${title(module.storage_account.name)}PrivateEndpoint"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[var.pe_subnet_name]
  private_connection_resource_id = module.storage_account.id
  is_manual_connection           = false
  subresource_name               = "blob"
  private_dns_zone_group_name    = "BlobPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.blob_private_dns_zone.id]
}

############## KEY VAULT ##########################
module "key_vault" {
  source              = "./modules/key_vault"
  name                = "orkv${random_string.storage_account_suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  ip_rules            = ["109.64.113.74"]

  virtual_network_subnet_ids = [
    module.vnet.subnet_ids[var.appserivce_subnet_name]
  ]
}

module "key_vault_private_dns_zone" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
  depends_on = [
    module.vnet
  ]
}

module "key_vault_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "${title(module.key_vault.name)}PrivateEndpoint"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[var.pe_subnet_name]
  private_connection_resource_id = module.key_vault.id
  is_manual_connection           = false
  subresource_name               = "vault"
  private_dns_zone_group_name    = "KeyVaultPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.key_vault_private_dns_zone.id]

  depends_on = [
    module.vnet,
    module.key_vault_private_dns_zone
  ]
}

###### APP SERVICE ###########
module "app_service" {
  source              = "./modules/app_service"
  app_service_name    = "orrestapi${random_string.storage_account_suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_subnet_id      = module.vnet.subnet_ids[var.appserivce_subnet_name]

  app_settings = {
    "STORAGE_ACCOUNT_NAME" = module.storage_account.name
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = module.app_service.app_service_id
  subnet_id      = module.vnet.subnet_ids[var.appserivce_subnet_name]

  depends_on = [module.app_service, module.vnet]
}

resource "azurerm_role_assignment" "app_service_blob_storage_access" {
  principal_id         = module.app_service.identity_principal_id
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
}

# Access policy to allow the App Service managed identity to manage Key Vault secrets
resource "azurerm_key_vault_access_policy" "app_service_secrets_policy" {
  key_vault_id = module.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.app_service.identity_principal_id

  # Permissions for secrets
  secret_permissions = [
    "Get",
    "List",
    "Set"
  ]
}
