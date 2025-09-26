resource "azurerm_key_vault" "this" {
  name                       = var.cfg.name
  location                   = var.cfg.location
  resource_group_name        = var.cfg.resource_group_name
  tenant_id                  = coalesce(var.cfg.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name                   = var.cfg.sku_name
  purge_protection_enabled   = var.cfg.purge_protection
  soft_delete_retention_days = var.cfg.soft_delete_retention_days
  enable_rbac_authorization  = true
  public_network_access_enabled = true
  tags = var.cfg.tags
}
data "azurerm_client_config" "current" {}

output "id"       { value = azurerm_key_vault.this.id }
output "vault_uri"{ value = azurerm_key_vault.this.vault_uri }
