variable "cfg" {
  type = object({
    name                = string
    location            = string
    resource_group_name = string
    sku                 = string
    queues              = list(string)
    tags                = map(string)
  })
}
