variable "location" {
  type = string
  description = "Location of Runbook"
  default = "uksouth"
}
variable "resource_group_name" {
  type = string
  description = "Resource Group Name"
}

variable "environment" {
  type = string
  description = "Environment Name e.g. sbox"
}
variable "product" {
  type = string
  description = "Product prefix"
}

variable "key_vault_name" {
  type = string
  description = "Key Vault Name to store secrets"
}

variable "automation_account_name" {
  type = string
  description = "Automation Account Name"
}

variable "target_tenant_id" {
  type = string
  description = "Target Active Directory Tenant ID. If empty it will use current context"
  default = ""
}
variable "target_managed_identity_id" {
  type = string
  description = "Managed Identity ID with access to Tenant. If target_tenant_id is empty this will not be used."
  default = ""
}