variable "project_id" {
  description = "Google Cloud project that owns the workshop instances."
  type        = string
}

variable "region" {
  description = "Google Cloud region."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone for workshop instances."
  type        = string
  default     = "us-central1-a"
}

variable "network" {
  description = "VPC network name or self-link."
  type        = string
  default     = "default"
}

variable "attendee_count" {
  description = "Total number of workshop attendees."
  type        = number
  default     = 1

  validation {
    condition     = var.attendee_count >= 1 && var.attendee_count <= 500 && var.attendee_count == floor(var.attendee_count)
    error_message = "attendee_count must be a whole number between 1 and 500."
  }
}

variable "attendees_per_node" {
  description = "Number of attendees sharing each workshop VM."
  type        = number
  default     = 2

  validation {
    condition     = var.attendees_per_node >= 2 && var.attendees_per_node <= 5 && var.attendees_per_node == floor(var.attendees_per_node)
    error_message = "attendees_per_node must be a whole number between 2 and 5."
  }
}

variable "name_prefix" {
  description = "Prefix used for node names and firewall tags."
  type        = string
  default     = "sandbox"
}

variable "boot_image" {
  description = "Ubuntu image family used for workshop nodes."
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
}

variable "source_ranges" {
  description = "Explicit CIDR ranges allowed to reach SSH and ttyd. Do not use 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.source_ranges) > 0 && alltrue([for source_range in var.source_ranges : can(cidrhost(source_range, 0)) && source_range != "0.0.0.0/0"])
    error_message = "source_ranges must contain at least one valid, restricted CIDR and must not include 0.0.0.0/0."
  }
}
