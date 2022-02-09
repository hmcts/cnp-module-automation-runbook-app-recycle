locals {
  today      = timestamp()
  start_date = formatdate("YYYY-MM-DD", timeadd(local.today, "24h"))
  start_time = "01:00:00"
}

resource "azurerm_automation_schedule" "client_serects" {
  name                    = "rotate-client-secrets-schedule"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "Day"
  interval                = 1
  start_time              = "${local.start_date}'T'${local.start_time}Z"
  description             = "This is a schedule to automate the renewal and recycling of Client Secrects"
}

resource "azurerm_automation_schedule" "client_serects_trigger_once" {
  name                    = "rotate-client-secrets-schedule-single-trigger"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "OneTime"
  description             = "This is a one time trigger to automate the renewal and recycling of Client Secrects"
}