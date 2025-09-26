resource "azurerm_container_registry" "this" {
  name                = var.cfg.name
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  sku                 = var.cfg.sku
  admin_enabled       = var.cfg.admin_enabled
  tags                = var.cfg.tags
}

output "id"           { value = azurerm_container_registry.this.id }
output "login_server" { value = azurerm_container_registry.this.login_server }
