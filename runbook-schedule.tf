data "azurerm_client_config" "current" {}
locals {
  source_managed_identity_id = var.source_managed_identity_id == "" ? data.azurerm_client_config.current.object_id : var.source_managed_identity_id
  source_tenant_id           = data.azurerm_client_config.current.tenant_id

  today      = timestamp()
  start_date = formatdate("YYYY-MM-DD", timeadd(local.today, "24h"))
  start_time = "01:00:00"

  parameters = {
    servicePrincipalIdCollection = jsonencode(var.application_id_collection)
    sourceTenantId               = local.source_tenant_id
    sourceClientId               = local.source_managed_identity_id
    targetTenantId               = var.target_tenant_id
    targetApplicationId          = var.target_application_id
    targetApplicationSecret      = var.target_application_secret
    environment                  = var.environment
    product                      = var.product
    prefix                       = "auto-"
    keyVaultName                 = var.key_vault_name
  }
}

resource "azurerm_automation_schedule" "client_serects" {
  name                    = "rotate-client-secrets-schedule"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "Day"
  interval                = 1
  start_time              = "${local.start_date}T${local.start_time}Z"
  description             = "This is a schedule to automate the renewal and recycling of Client Secrects"
}

resource "azurerm_automation_schedule" "client_serects_trigger_once" {
  name                    = "rotate-client-secrets-schedule-single-trigger"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "OneTime"
  start_time              = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timeadd(local.today, "10m"))
  description             = "This is a one time trigger to automate the renewal and recycling of Client Secrects"
}

resource "azurerm_automation_job_schedule" "client_serects" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  schedule_name           = azurerm_automation_schedule.client_serects.name
  runbook_name            = azurerm_automation_runbook.client_serects.name
  parameters              = local.parameters
  depends_on              = [azurerm_automation_schedule.client_serects]
}

resource "azurerm_automation_job_schedule" "client_serects_trigger_once" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  schedule_name           = azurerm_automation_schedule.client_serects_trigger_once.name
  runbook_name            = azurerm_automation_runbook.client_serects.name
  parameters              = local.parameters
  depends_on              = [azurerm_automation_schedule.client_serects_trigger_once]
}