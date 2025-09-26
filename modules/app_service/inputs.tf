variable "cfg" {
  type = object({
    plan_name           = string
    sku_name            = string
    app_name            = string
    location            = string
    resource_group_name = string
    app_settings        = map(string)
    tags                = map(string)
  })
}
