
resource "azurerm_automation_variable_string" "target_tenant_id" {
  name                    = "targetTenantId"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.target_tenant_id
}
resource "azurerm_automation_variable_string" "target_client_id" {
  name                    = "targetClientId"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.target_managed_identity_id
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
resource "azurerm_automation_variable_string" "key_vault_name" {
  name                    = "keyVaultName"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = var.key_vault_name
}