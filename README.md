# Automation Runbook for Application secret recycling

This module is to setup a Azure Automation Runbook to recycle Application Secrets.

This will do the following:
- Remove expired secrets created by the runbook
- Create secondary secrets for secrets due to expire
- Create secrets for Application that do not have secrets.

All secrets will be prefixed with `auto-` to highlight they are created via the runbook.

## Example

Below is the standard example setup

```terraform
module "automation_runbook_client_secret_rotation" {
  source      = "git@github.com:hmcts/cnp-module-automation-runbook-app-recycle?ref=master"

  resource_group_name = "my-resource-group"

  application_id_collection = [
    "6d992660-4d87-4294-8007-dbf7b6c0a1e5",
    "60779d15-7cf9-46ab-ba6a-b77b64ef5093"
  ]

  environment = "sbox"
  product     = "hcm"

  key_vault_name  = "hcm-kv-sbox"

  automation_account_name = "hcm-automation"

}
```

### Optional
If the target Tenant is not accessible via the Managed Identity, then you can provide Service Principal credentials to authenticate and validate against that tenant.

Additional Variables are
```terraform

  target_tenant_id          = "8efd196a-f993-410c-a8f0-5f0c9296b3a0"
  target_application_id     = "fa63789d-f097-4b6d-812b-397e7c21d655"
  target_application_secret = "ROkB:nk8ML+D}E/"

```

### Terraform Spec

## Requirements   

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 2.95.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_automation_job_schedule.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
| [azurerm_automation_job_schedule.client_serects_trigger_once](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |    
| [azurerm_automation_runbook.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | resource |
| [azurerm_automation_schedule.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_automation_schedule.client_serects_trigger_once](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_id_collection"></a> [application\_id\_collection](#input\_application\_id\_collection) | List of Application IDs to manage | `list(string)` | `[]` | no |   
| <a name="input_automation_account_name"></a> [automation\_account\_name](#input\_automation\_account\_name) | Automation Account Name | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name e.g. sbox | `string` | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Key Vault Name to store secrets | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location of Runbook | `string` | `"uksouth"` | no |
| <a name="input_product"></a> [product](#input\_product) | Product prefix | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group Name | `string` | n/a | yes |
| <a name="input_source_managed_identity_id"></a> [source\_managed\_identity\_id](#input\_source\_managed\_identity\_id) | Managed Identity to authenticate with. Default will use current context. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Runbook Tags | `map(string)` | n/a | yes |
| <a name="input_target_application_id"></a> [target\_application\_id](#input\_target\_application\_id) | Application ID with access to Tenant. If target\_tenant\_id is empty this will 
not be used. | `string` | `""` | no |
| <a name="input_target_application_secret"></a> [target\_application\_secret](#input\_target\_application\_secret) | Application Secret with access to Tenant. If target\_tenant\_id is 
empty this will not be used. | `string` | `""` | no |
| <a name="input_target_tenant_id"></a> [target\_tenant\_id](#input\_target\_tenant\_id) | Target Active Directory Tenant ID. If empty it will use current context | `string` | `""` | no |

## Outputs

No outputs.