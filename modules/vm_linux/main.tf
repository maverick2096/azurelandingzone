resource "azurerm_network_interface" "nic" {
  name                = "${var.cfg.name}-nic"
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.cfg.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.cfg.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.cfg.name
  location            = var.cfg.location
  resource_group_name = var.cfg.resource_group_name
  size                = var.cfg.vm_size
  admin_username      = var.cfg.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.cfg.admin_username
    public_key = var.cfg.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.cfg.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.cfg.image.publisher
    offer     = var.cfg.image.offer
    sku       = var.cfg.image.sku
    version   = var.cfg.image.version
  }

  tags = var.cfg.tags
}

output "vm_id" { value = azurerm_linux_virtual_machine.vm.id }
