variable "cfg" {
  type = object({
    name                = string
    location            = string
    resource_group_name = string
    sku                 = string
    retention_days      = number
    tags                = map(string)
  })
}
