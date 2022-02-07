
locals {
  runbook_name    = "client_secrets.ps1"
  runbook_content = file("./${local.runbook_name}")
}

resource "azurerm_automation_runbook" "client_serects" {
  name                    = "rotate-client-secrets"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = var.environment == "prod" ? "false" : "true"
  log_progress            = "true"
  description             = "This is a runbook to automate the renewal and recycling of Client Secrects"
  runbook_type            = "PowerShell"

  content = local.runbook_content
}