############################
# Resource Group
############################
module "resource_group" {
  source = "./modules/resource_group"
  count  = local.enable_rg ? 1 : 0

  cfg = {
    name     = var.rg_name
    location = var.location
    tags     = var.tags
  }
}

############################
# ACR
############################
module "acr" {
  source = "./modules/acr"
  count  = local.enable_acr ? 1 : 0

  cfg = {
    name                = var.acr_name
    location            = var.location
    resource_group_name = var.rg_name
    sku                 = var.acr_sku
    admin_enabled       = var.acr_admin_enabled
    tags                = var.tags
  }
}

############################
# Key Vault
############################
module "key_vault" {
  source = "./modules/key_vault"
  count  = local.enable_kv ? 1 : 0

  cfg = {
    name                         = var.kv_name
    location                     = var.location
    resource_group_name          = var.rg_name
    tenant_id                    = null            # uses current subscription tenant when null
    sku_name                     = var.kv_sku
    purge_protection             = var.kv_purge_protection
    soft_delete_retention_days   = var.kv_soft_delete_retention_days
    tags                         = var.tags
  }
}

############################
# Log Analytics
############################
module "log_analytics" {
  source = "./modules/log_analytics"
  count  = local.enable_law ? 1 : 0

  cfg = {
    name                = var.log_analytics_name
    location            = var.location
    resource_group_name = var.rg_name
    sku                 = var.log_analytics_sku
    retention_days      = var.log_analytics_retention_days
    tags                = var.tags
  }
}

############################
# VM (Linux)
############################
module "vm" {
  source = "./modules/vm_linux"
  count  = local.enable_vm ? 1 : 0

  cfg = {
    name            = var.vm_name
    location        = var.location
    resource_group_name = var.rg_name
    subnet_id       = var.vm_subnet_id
    admin_username  = var.vm_admin_user
    ssh_public_key  = var.vm_ssh_public_key
    vm_size         = var.vm_size
    os_disk_size_gb = var.vm_os_disk_size_gb
    image           = var.vm_image
    tags            = var.tags
  }
}

############################
# Service Bus
############################
module "servicebus" {
  source = "./modules/servicebus"
  count  = local.enable_servicebus ? 1 : 0

  cfg = {
    name                = var.sb_namespace_name
    location            = var.location
    resource_group_name = var.rg_name
    sku                 = var.sb_sku
    queues              = var.sb_queues
    tags                = var.tags
  }
}

############################
# App Service
############################
module "app_service" {
  source = "./modules/app_service"
  count  = local.enable_app_service ? 1 : 0

  cfg = {
    plan_name           = var.app_service_plan_name
    sku_name            = var.app_service_sku
    app_name            = var.app_name
    location            = var.location
    resource_group_name = var.rg_name
    app_settings        = var.app_settings
    tags                = var.tags
  }
}

############################
# Storage Account
############################
module "storage" {
  source = "./modules/storage_account"
  count  = local.enable_storage ? 1 : 0

  cfg = {
    name                    = var.sa_name
    location                = var.location
    resource_group_name     = var.rg_name
    account_tier            = var.sa_tier
    account_replication_type= var.sa_replication
    containers              = var.storage_containers
    tags                    = var.tags
  }
}

############################
# Outputs
############################
output "resource_group_name" {
  value = local.enable_rg ? module.resource_group[0].name : var.rg_name
}
output "acr_login_server" {
  value = local.enable_acr ? module.acr[0].login_server : null
}
output "kv_uri" {
  value = local.enable_kv ? module.key_vault[0].vault_uri : null
}
output "log_analytics_id" {
  value = local.enable_law ? module.log_analytics[0].id : null
}
output "vm_id" {
  value = local.enable_vm ? module.vm[0].vm_id : null
}
output "servicebus_namespace_id" {
  value = local.enable_servicebus ? module.servicebus[0].namespace_id : null
}
output "app_service_hostname" {
  value = local.enable_app_service ? module.app_service[0].default_hostname : null
}
output "storage_account_id" {
  value = local.enable_storage ? module.storage[0].id : null
}
