# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "deployer" {
  description = "Override for deployer identifier (auto-resolved from Azure AD if empty). Required for service principal or managed identity authentication."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment label used in resource group naming and tags"
  type        = string
  default     = "lab"
}

variable "tags" {
  description = "Additional tags merged with standard tags (component, environment, deployer, managed_by)"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------
# Compute
# ---------------------------------------------------------

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

variable "disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

# ---------------------------------------------------------
# Component-Specific
# ---------------------------------------------------------

variable "origin_server" {
  description = "Origin server URL that the CDN edge forwards cache misses to (e.g., https://72.19.3.185 for F5 XC, or http://origin-ip for direct)"
  type        = string
}

variable "origin_host" {
  description = "Origin server host:port for NGINX upstream (no scheme). Use IP:443 for HTTPS or IP:80 for HTTP."
  type        = string
}
