terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

variable "location" {
  description = "Azure region in which to create all resources."
  type        = string
  default     = "swedencentral"
}

variable "sql_entra_administrator_login" {
  description = "Display name used for the Azure SQL Microsoft Entra administrator."
  type        = string
  default     = "terraform-deployer"
}

variable "sql_entra_administrator_object_id" {
  description = "Object ID of the user, group, or service principal used as the Azure SQL Microsoft Entra administrator. Defaults to the identity running Terraform."
  type        = string
  default     = null
  nullable    = true
}

variable "container_image" {
  description = "Container image to deploy. Replace the default with the immutable ContosoUniversity ACR image tag after pushing it."
  type        = string
  default     = "crcontosobetis20262027.azurecr.io/contoso-university:20260916-190532"
}

variable "container_target_port" {
  description = "Port exposed by container_image. Use 8080 for the ContosoUniversity image."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_target_port >= 1 && var.container_target_port <= 65535
    error_message = "container_target_port must be between 1 and 65535."
  }
}

variable "container_cpu" {
  description = "CPU cores allocated to the Container App."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory allocated to the Container App."
  type        = string
  default     = "1Gi"
}

variable "tags" {
  description = "Tags applied to supported Azure resources."
  type        = map(string)
  default = {
    application = "ContosoUniversity"
    environment = "test"
    managed-by  = "Terraform"
    team        = "BETIS"
  }
}

locals {
  resource_group_name         = "rg-contoso-BETIS"
  sql_server_name             = "sql-contoso-betis"
  sql_database_name           = "ContosoUniversity"
  servicebus_namespace_name   = "sbns-contoso-betis"
  servicebus_queue_name       = "contoso-university-notifications"
  storage_account_name        = "stcontosobetis20262027"
  storage_container_name      = "teaching-materials"
  container_registry_name     = "crcontosobetis20262027"
  container_app_environment   = "cae-contoso-betis"
  container_app_name          = "ca-contoso-betis"
  sql_administrator_object_id = coalesce(var.sql_entra_administrator_object_id, data.azurerm_client_config.current.object_id)
}

resource "azurerm_resource_group" "contoso" {
  name     = local.resource_group_name
  location = var.location
  tags = merge(var.tags, {
    SecurityControl = "Ignore"
  })
}

resource "azurerm_mssql_server" "contoso" {
  name                          = local.sql_server_name
  resource_group_name           = azurerm_resource_group.contoso.name
  location                      = azurerm_resource_group.contoso.location
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  tags                          = var.tags

  azuread_administrator {
    login_username              = var.sql_entra_administrator_login
    object_id                   = local.sql_administrator_object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = true
  }

  depends_on = [azurerm_resource_group.contoso]
}

resource "azurerm_mssql_database" "contoso" {
  name        = local.sql_database_name
  server_id   = azurerm_mssql_server.contoso.id
  sku_name    = "Basic"
  max_size_gb = 2
  tags        = var.tags
}

# This permits connections from Azure-hosted services. For production, replace
# public access with private endpoints and controlled network integration.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.contoso.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_servicebus_namespace" "contoso" {
  name                = local.servicebus_namespace_name
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  sku                 = "Standard"
  local_auth_enabled  = false
  minimum_tls_version = "1.2"
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "notifications" {
  name         = local.servicebus_queue_name
  namespace_id = azurerm_servicebus_namespace.contoso.id

  max_delivery_count = 10
}

resource "azurerm_storage_account" "contoso" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.contoso.name
  location                        = azurerm_resource_group.contoso.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  tags                            = var.tags
}

resource "azurerm_storage_container" "teaching_materials" {
  name                  = local.storage_container_name
  storage_account_name  = azurerm_storage_account.contoso.name
  container_access_type = "private"
}

resource "azurerm_container_registry" "contoso" {
  name                = local.container_registry_name
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_container_app_environment" "contoso" {
  name                = local.container_app_environment
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  tags                = var.tags
}

resource "azurerm_container_app" "contoso" {
  name                         = local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.contoso.id
  resource_group_name          = azurerm_resource_group.contoso.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }

  registry {
    server   = azurerm_container_registry.contoso.login_server
    identity = "system"
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.container_target_port
    transport                  = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "contoso-university"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://+:${var.container_target_port}"
      }

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }

      env {
        name  = "ASPNETCORE_FORWARDEDHEADERS_ENABLED"
        value = "true"
      }

      env {
        name  = "ConnectionStrings__DefaultConnection"
        value = "Server=tcp:${azurerm_mssql_server.contoso.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.contoso.name};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Default;"
      }

      env {
        name  = "AzureServiceBus__FullyQualifiedNamespace"
        value = "${azurerm_servicebus_namespace.contoso.name}.servicebus.windows.net"
      }

      env {
        name  = "AzureServiceBus__NotificationQueueName"
        value = azurerm_servicebus_queue.notifications.name
      }

      env {
        name  = "Storage__ServiceUri"
        value = azurerm_storage_account.contoso.primary_blob_endpoint
      }

      env {
        name  = "Storage__TeachingMaterialsContainerName"
        value = azurerm_storage_container.teaching_materials.name
      }
    }
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.contoso.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.contoso.identity[0].principal_id
}

resource "azurerm_role_assignment" "servicebus_sender" {
  scope                = azurerm_servicebus_namespace.contoso.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_container_app.contoso.identity[0].principal_id
}

resource "azurerm_role_assignment" "servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.contoso.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_container_app.contoso.identity[0].principal_id
}

resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.contoso.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_container_app.contoso.identity[0].principal_id
}

output "resource_group_name" {
  value = azurerm_resource_group.contoso.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.contoso.login_server
}

output "container_app_url" {
  value = "https://${azurerm_container_app.contoso.latest_revision_fqdn}"
}

output "container_app_principal_id" {
  value = azurerm_container_app.contoso.identity[0].principal_id
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.contoso.fully_qualified_domain_name
}

output "sql_database_name" {
  value = azurerm_mssql_database.contoso.name
}

output "servicebus_fully_qualified_namespace" {
  value = "${azurerm_servicebus_namespace.contoso.name}.servicebus.windows.net"
}

output "storage_blob_service_uri" {
  value = azurerm_storage_account.contoso.primary_blob_endpoint
}

output "sql_managed_identity_bootstrap" {
  description = "Connect to the ContosoUniversity database as the configured Microsoft Entra administrator and execute these statements before deploying the real application image."
  value       = <<-SQL
    CREATE USER [${azurerm_container_app.contoso.name}] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [${azurerm_container_app.contoso.name}];
    ALTER ROLE db_datawriter ADD MEMBER [${azurerm_container_app.contoso.name}];
    ALTER ROLE db_ddladmin ADD MEMBER [${azurerm_container_app.contoso.name}];
  SQL
}

output "real_image_apply_example" {
  description = "Example values for switching from the temporary image to an immutable ContosoUniversity image in ACR."
  value       = "terraform apply -var=\"container_image=${azurerm_container_registry.contoso.login_server}/contoso-university:<immutable-tag>\" -var=\"container_target_port=8080\""
}