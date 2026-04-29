variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name for the Azure resource group"
  type        = string
  default     = "rg-cdn-simulator"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "vm_size" {
  description = "Azure VM size — F-series compute-optimized recommended (F4s_v2 for lab, F16s_v2 for load testing, F32s_v2 for production)"
  type        = string
  default     = "Standard_F4s_v2"
}

variable "admin_username" {
  description = "SSH admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "origin_server" {
  description = "Origin server URL that the CDN edge forwards cache misses to (e.g., https://72.19.3.185 for F5 XC, or http://origin-ip for direct)"
  type        = string
}

variable "origin_host" {
  description = "Origin server host:port for NGINX upstream (no scheme). Use IP:443 for HTTPS or IP:80 for HTTP."
  type        = string
}

variable "environment_tag" {
  description = "Environment tag applied to all resources"
  type        = string
  default     = "lab"
}
