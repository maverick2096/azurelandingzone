resource "azurerm_log_analytics_workspace" "this" {
  name                = var.cfg.name
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  sku                 = var.cfg.sku
  retention_in_days   = var.cfg.retention_days
  tags                = var.cfg.tags
}

output "id"   { value = azurerm_log_analytics_workspace.this.id }
output "name" { value = azurerm_log_analytics_workspace.this.name }
