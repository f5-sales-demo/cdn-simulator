# ---------------------------------------------------------
# Standard Outputs (present in every demo resource)
# ---------------------------------------------------------

output "deployer" {
  description = "Resolved deployer identifier"
  value       = local.deployer
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region"
  value       = azurerm_resource_group.main.location
}

output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_id" {
  description = "Resource ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "nsg_name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.main.name
}

output "nsg_id" {
  description = "Resource ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "Resource ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "component" {
  description = "Component name"
  value       = local.component
}

output "environment" {
  description = "Environment label"
  value       = var.environment
}

# ---------------------------------------------------------
# Component-Specific Outputs
# ---------------------------------------------------------

output "edge_url" {
  description = "HTTP URL of the CDN edge node"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "http://${azurerm_public_ip.main.ip_address}/health"
}

output "edge_fqdn" {
  description = "Stable cloudapp.azure.com FQDN of the CDN edge node (used as the CSD demo third-party host)"
  value       = azurerm_public_ip.main.fqdn
}
