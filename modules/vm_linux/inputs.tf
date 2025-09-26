variable "cfg" {
  type = object({
    name                = string
    location            = string
    resource_group_name = string
    subnet_id           = string
    admin_username      = string
    ssh_public_key      = string
    vm_size             = string
    os_disk_size_gb     = number
    image               = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    tags = map(string)
  })
}
