resource "azurerm_storage_account" "this" {
  name                             = var.cfg.name
  location                         = var.cfg.location
  resource_group_name              = var.cfg.resource_group_name
  account_tier                     = var.cfg.account_tier
  account_replication_type         = var.cfg.account_replication_type
  min_tls_version                  = "TLS1_2"
  public_network_access_enabled    = true
  allow_nested_items_to_be_public  = false
  tags = var.cfg.tags
}

resource "azurerm_storage_container" "container" {
  for_each              = toset(var.cfg.containers)
  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

output "id" { value = azurerm_storage_account.this.id }
