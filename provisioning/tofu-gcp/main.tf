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
  node_names = [for index in range(var.attendee_count) : format("%s-%02d", var.name_prefix, index + 1)]
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
  count        = var.attendee_count
  name         = local.node_names[count.index]
  machine_type = "n2-standard-4"
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

  min_cpu_platform        = "Intel Cascade Lake"
  metadata_startup_script = file("${path.module}/../scripts/setup-node.sh")
}
