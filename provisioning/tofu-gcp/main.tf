terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  node_count = ceil(var.attendee_count / var.attendees_per_node)
  node_names = [for index in range(local.node_count) : format("%s-%02d", var.name_prefix, index + 1)]
}

resource "google_compute_firewall" "workshop" {
  name    = "${var.name_prefix}-allow-workshop"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22", "7681"]
  }

  source_ranges = var.source_ranges
  target_tags   = [var.name_prefix]
}

resource "google_compute_instance" "node" {
  count        = local.node_count
  name         = local.node_names[count.index]
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.name_prefix]

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = 50
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = var.network

    access_config {}
  }

  advanced_machine_features {
    enable_nested_virtualization = true
  }

  min_cpu_platform        = var.min_cpu_platform
  metadata_startup_script = file("${path.module}/../scripts/setup-node.sh")
}