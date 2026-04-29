resource "azurerm_linux_virtual_machine" "edge" {
  name                = "vm-cdn-edge"
  resource_group_name = azurerm_resource_group.cdn.name
  location            = azurerm_resource_group.cdn.location
  size                = var.vm_size

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [azurerm_network_interface.edge.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    origin_server = var.origin_server
    origin_host   = var.origin_host
  }))

  boot_diagnostics {}

  tags = azurerm_resource_group.cdn.tags
}
