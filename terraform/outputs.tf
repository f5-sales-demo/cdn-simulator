output "public_ip" {
  description = "Public IP address of the CDN edge node"
  value       = azurerm_public_ip.edge.ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the edge node"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.edge.ip_address}"
}

output "edge_url" {
  description = "HTTP URL of the CDN edge node"
  value       = "http://${azurerm_public_ip.edge.ip_address}"
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "http://${azurerm_public_ip.edge.ip_address}/health"
}

output "resource_group" {
  description = "Resource group containing all CDN simulator resources"
  value       = azurerm_resource_group.cdn.name
}
