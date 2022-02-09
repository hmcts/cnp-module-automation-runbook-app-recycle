variable "location" {
  type        = string
  description = "Location of Runbook"
  default     = "uksouth"
}
variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}
variable "tags" {
  type        = map(string)
  description = "Runbook Tags"
}

variable "application_id_collection" {
  type        = list(string)
  description = "List of Application IDs to manage"
  default     = []
}

variable "source_managed_identity_id" {
  type        = string
  description = "Managed Identity to authenticate with. Default will use current context."
  default     = ""
}


variable "environment" {
  type        = string
  description = "Environment Name e.g. sbox"
}
variable "product" {
  type        = string
  description = "Product prefix"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault Name to store secrets"
}

variable "automation_account_name" {
  type        = string
  description = "Automation Account Name"
}

variable "target_tenant_id" {
  type        = string
  description = "Target Active Directory Tenant ID. If empty it will use current context"
  default     = ""
}
variable "target_application_id" {
  type        = string
  description = "Application ID with access to Tenant. If target_tenant_id is empty this will not be used."
  default     = ""
}
variable "target_application_secret" {
  type        = string
  description = "Application Secret with access to Tenant. If target_tenant_id is empty this will not be used."
  default     = ""
  sensitive   = true
}
