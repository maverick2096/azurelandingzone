variable "cfg" {
  type = object({
    name                    = string
    location                = string
    resource_group_name     = string
    account_tier            = string
    account_replication_type= string
    containers              = list(string)
    tags                    = map(string)
  })
}
