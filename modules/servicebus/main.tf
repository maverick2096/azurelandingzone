resource "azurerm_servicebus_namespace" "ns" {
  name                = var.cfg.name
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  sku                 = var.cfg.sku
  tags                = var.cfg.tags
}

resource "azurerm_servicebus_queue" "q" {
  for_each            = toset(var.cfg.queues)
  name                = each.key
  namespace_id        = azurerm_servicebus_namespace.ns.id
  enable_partitioning = true
}

output "namespace_id" { value = azurerm_servicebus_namespace.ns.id }
