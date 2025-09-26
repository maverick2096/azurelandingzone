resource "azurerm_resource_group" "this" {
  name     = var.cfg.name
  location = var.cfg.location
  tags     = var.cfg.tags
}

output "name"     { value = azurerm_resource_group.this.name }
output "location" { value = azurerm_resource_group.this.location }
