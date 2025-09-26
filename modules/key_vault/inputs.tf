variable "cfg" {
  type = object({
    name                         = string
    location                     = string
    resource_group_name          = string
    tenant_id                    = any
    sku_name                     = string
    purge_protection             = bool
    soft_delete_retention_days   = number
    tags                         = map(string)
  })
}
