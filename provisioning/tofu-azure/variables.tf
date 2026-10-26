variable "location" {
  description = "Azure region for all workshop resources. Choose a region with available student quota."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Lowercase prefix used for Azure resource names."
  type        = string
  default     = "sandbox"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.name_prefix))
    error_message = "name_prefix must be 1-20 characters containing only lowercase letters, numbers, and hyphens."
  }
}

variable "admin_username" {
  description = "Administrator account for SSH access."
  type        = string
  default     = "azureadmin"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.admin_username)) && var.admin_username != "root"
    error_message = "admin_username must be a valid non-root Linux username."
  }
}

variable "admin_ssh_public_key" {
  description = "SSH public key installed on the shared workshop host."
  type        = string
  sensitive   = true
}

variable "allowed_source_cidrs" {
  description = "CIDR ranges allowed to reach SSH and ttyd. Restrict this to the workshop network where possible."
  type        = list(string)

  validation {
    condition = length(var.allowed_source_cidrs) > 0 && alltrue([
      for cidr in var.allowed_source_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "allowed_source_cidrs must contain at least one valid CIDR."
  }
}

variable "vnet_address_space" {
  description = "Address space for the workshop virtual network."
  type        = string
  default     = "10.42.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the workshop subnet."
  type        = string
  default     = "10.42.1.0/24"
}

variable "ttyd_version" {
  description = "ttyd release installed on the shared host."
  type        = string
  default     = "1.7.7"
}
