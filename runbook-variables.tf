
data "azurerm_client_config" "current" {}
locals {
  source_managed_identity_id = var.source_managed_identity_id != "" ? var.source_managed_identity_id : data.azurerm_client_config.current.object_id
  source_tenant_id           = data.azurerm_client_config.current.tenant_id
}


resource "azurerm_automation_variable_string" "application_id_collection" {
  name                    = "servicePrincipalIdCollection"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = jsonencode(var.application_id_collection)
}

resource "azurerm_automation_variable_string" "source_tenant_id" {
  name                    = "sourceTenantId"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = local.source_tenant_id
}
resource "azurerm_automation_variable_string" "source_client_id" {
  name                    = "sourceClientId"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = local.source_managed_identity_id
}

resource "azurerm_automation_variable_string" "target_tenant_id" {
  name                    = "targetTenantId"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.target_tenant_id
}
resource "azurerm_automation_variable_string" "target_application_id" {
  name                    = "targetApplicationId"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.target_application_id
}
resource "azurerm_automation_variable_string" "target_application_secret" {
  name                    = "targetApplicationSecret"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.target_application_secret
  encrypted               = true
}

resource "azurerm_automation_variable_string" "environment" {
  name                    = "environment"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.environment
}
resource "azurerm_automation_variable_string" "product" {
  name                    = "product"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.product
}
resource "azurerm_automation_variable_string" "secret_prefix" {
  name                    = "prefix"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = "auto-"
}
resource "azurerm_automation_variable_string" "key_vault_name" {
  name                    = "keyVaultName"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.key_vault_name
}
