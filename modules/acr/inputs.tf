variable "cfg" {
  type = object({
    name                = string
    location            = string
    resource_group_name = string
    sku                 = string
    admin_enabled       = bool
    tags                = map(string)
  })
}
