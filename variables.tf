#########################
# Global
#########################
variable "location" {
  description = "Azure region for all resources"
  type        = string
}
variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

#########################
# yes/no build toggles
#########################
variable "build_resource_group" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_resource_group))
    error_message = "build_resource_group must be 'yes' or 'no'." }
}
variable "build_acr" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_acr))
    error_message = "build_acr must be 'yes' or 'no'." }
}
variable "build_key_vault" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_key_vault))
    error_message = "build_key_vault must be 'yes' or 'no'." }
}
variable "build_log_analytics" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_log_analytics))
    error_message = "build_log_analytics must be 'yes' or 'no'." }
}
variable "build_vm" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_vm))
    error_message = "build_vm must be 'yes' or 'no'." }
}
variable "build_servicebus" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_servicebus))
    error_message = "build_servicebus must be 'yes' or 'no'." }
}
variable "build_app_service" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_app_service))
    error_message = "build_app_service must be 'yes' or 'no'." }
}
variable "build_storage" { type = string
  validation { condition = contains(["yes","no"], lower(var.build_storage))
    error_message = "build_storage must be 'yes' or 'no'." }
}

locals {
  enable_rg          = lower(var.build_resource_group) == "yes"
  enable_acr         = lower(var.build_acr) == "yes"
  enable_kv          = lower(var.build_key_vault) == "yes"
  enable_law         = lower(var.build_log_analytics) == "yes"
  enable_vm          = lower(var.build_vm) == "yes"
  enable_servicebus  = lower(var.build_servicebus) == "yes"
  enable_app_service = lower(var.build_app_service) == "yes"
  enable_storage     = lower(var.build_storage) == "yes"
}

#########################
# Resource-specific inputs
#########################

# Resource Group
variable "rg_name" { type = string }

# ACR
variable "acr_name" { type = string
  validation { condition = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "acr_name must be lowercase alphanumeric, 5-50 chars." }
}
variable "acr_sku" { type = string
  validation { condition = contains(["Basic","Standard","Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic | Standard | Premium." }
}
variable "acr_admin_enabled" { type = bool }

# Key Vault (infra only)
variable "kv_name" { type = string }
variable "kv_sku"  { type = string, default = "standard"
  validation { condition = contains(["standard","premium"], lower(var.kv_sku))
    error_message = "kv_sku must be 'standard' or 'premium'." }
}
variable "kv_purge_protection"           { type = bool }
variable "kv_soft_delete_retention_days" { type = number }

# Log Analytics
variable "log_analytics_name" { type = string }
variable "log_analytics_sku"  { type = string, default = "PerGB2018" }
variable "log_analytics_retention_days" { type = number, default = 30 }

# VM (Linux)
variable "vm_name"            { type = string }
variable "vm_size"            { type = string, default = "Standard_DS2_v2" }
variable "vm_admin_user"      { type = string, default = "azureuser" }
variable "vm_ssh_public_key"  { type = string }
variable "vm_os_disk_size_gb" { type = number, default = 64 }
variable "vm_subnet_id"       { type = string } # Expect an existing subnet ID

variable "vm_image" {
  description = "Image reference"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Service Bus
variable "sb_namespace_name" { type = string }
variable "sb_sku"            { type = string, default = "Standard" }
variable "sb_queues"         { type = list(string), default = [] }

# App Service (Linux)
variable "app_service_plan_name" { type = string }
variable "app_service_sku"       { type = string, default = "P1v3" }
variable "app_name"              { type = string }
variable "app_settings"          { type = map(string), default = {} }

# Storage Account
variable "sa_name"                 { type = string
  validation { condition = can(regex("^[a-z0-9]{3,24}$", var.sa_name))
    error_message = "sa_name must be 3-24 lowercase alphanumeric." }
}
variable "sa_tier"                 { type = string, default = "Standard" }
variable "sa_replication"          { type = string, default = "GRS" }
variable "storage_containers"      { type = list(string), default = [] }
