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
