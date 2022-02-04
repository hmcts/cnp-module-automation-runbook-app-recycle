# Automation Runbook for Service Principal secret recycling

This module is to setup a Azure Automation Runbook to recycle Service Principal Secrets.

This will do the following:
- Remove expired secrets created by the runbook
- Create secondary secrets for secrets due to expire
- Create secrets for Service Principals that do not have secrets.

All secrets will be prefixed with `auto-` to highlight they are created via the runbook.

## Example

```terraform
module "apim_apis" {
  source      = "git::https://github.com/hmcts/cnp-module-automation-runbook-sp-recycle?ref=master"
  environment = "sbox"
  product     = "pip"
  department  = "sds"

}
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_automation_runbook.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | resource |
| [azurerm_automation_schedule.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_automation_schedule.client_serects_trigger_once](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource 
|
| [azurerm_automation_variable_string.environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource | 
| [azurerm_automation_variable_string.key_vault_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource |
| [azurerm_automation_variable_string.product](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource |     
| [azurerm_automation_variable_string.target_client_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource |
| [azurerm_automation_variable_string.target_tenant_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation_account_name"></a> [automation\_account\_name](#input\_automation\_account\_name) | Automation Account Name | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name e.g. sbox | `string` | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Key Vault Name to store secrets | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location of Runbook | `string` | `"uksouth"` | no |
| <a name="input_product"></a> [product](#input\_product) | Product prefix | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group Name | `string` | n/a | yes |
| <a name="input_target_managed_identity_id"></a> [target\_managed\_identity\_id](#input\_target\_managed\_identity\_id) | Managed Identity ID with access to Tenant. If target\_tenant\_id is empty this will not be used. | `string` | `""` | no |
| <a name="input_target_tenant_id"></a> [target\_tenant\_id](#input\_target\_tenant\_id) | Target Active Directory Tenant ID. If empty it will use current context | `string` | `""` | no |

## Outputs

No outputs.