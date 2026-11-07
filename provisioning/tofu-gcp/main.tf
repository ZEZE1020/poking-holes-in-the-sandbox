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
  workshop_materials = [
    "README.md",
    "lab1-runc/README.md",
    "lab1-runc/01-baseline-pod.yaml",
    "lab2-kata/README.md",
    "lab2-kata/01-kata-pod.yaml",
    "lab3-metrics/README.md",
    "lab3-metrics/stress-runc.yaml",
    "lab3-metrics/stress-kata.yaml",
  ]
  workshop_materials_bootstrap = join("\n", concat(
    ["install -d -m 0755 /home/workshop/workshop"],
    [for relative_path in local.workshop_materials :
      format(
        "printf '%%s' '%s' | base64 --decode > '/home/workshop/workshop/%s'",
        base64encode(file("${path.module}/../../${relative_path}")),
        relative_path,
      )
    ],
    ["chown -R workshop:workshop /home/workshop/workshop"],
  ))
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

  min_cpu_platform = var.min_cpu_platform
  metadata_startup_script = replace(
    file("${path.module}/../scripts/setup-node.sh"),
    "__WORKSHOP_MATERIALS_BOOTSTRAP__",
    local.workshop_materials_bootstrap,
  )
}