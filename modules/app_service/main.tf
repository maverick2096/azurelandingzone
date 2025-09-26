resource "azurerm_service_plan" "plan" {
  name                = var.cfg.plan_name
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  os_type             = "Linux"
  sku_name            = var.cfg.sku_name
  tags                = var.cfg.tags
}

resource "azurerm_linux_web_app" "app" {
  name                = var.cfg.app_name
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id
  identity { type = "SystemAssigned" }

  app_settings = var.cfg.app_settings

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }
  tags = var.cfg.tags
}

output "default_hostname" { value = azurerm_linux_web_app.app.default_hostname }
