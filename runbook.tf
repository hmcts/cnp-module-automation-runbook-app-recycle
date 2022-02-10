
locals {
  runbook_name    = "client_secrets.ps1"
  runbook_content = file("${path.module}/${local.runbook_name}")
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

  ## TODO: maybe need to also provide a link?
  content = local.runbook_content

  tags = var.tags
}

resource "azurerm_automation_module" "az_graph" {
  name                    = "Microsoft.Graph"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/microsoft.graph.1.9.2.nupkg"
  }
}