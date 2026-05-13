################################################################################
# GCP VPC Module
# ssktraining.dev — Terraform Multi-Cloud Kit
# Production-grade VPC with custom subnets, private Google access, Cloud NAT
################################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ── VPC Network ────────────────────────────────────────────────────────────────
resource "google_compute_network" "this" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  project                 = var.project_id

  description = "Managed by Terraform — ShipStack Multi-Cloud Kit"
}

# ── Subnets ────────────────────────────────────────────────────────────────────
resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name                     = each.key
  ip_cidr_range            = each.value.cidr
  region                   = each.value.region
  network                  = google_compute_network.this.self_link
  project                  = var.project_id
  private_ip_google_access = true

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ── Cloud Router (for Cloud NAT) ───────────────────────────────────────────────
resource "google_compute_router" "this" {
  for_each = var.enable_cloud_nat ? toset(distinct([for s in values(var.subnets) : s.region])) : []

  name    = "${var.network_name}-router-${each.key}"
  region  = each.key
  network = google_compute_network.this.self_link
  project = var.project_id
}

# ── Cloud NAT ──────────────────────────────────────────────────────────────────
resource "google_compute_router_nat" "this" {
  for_each = var.enable_cloud_nat ? google_compute_router.this : {}

  name                               = "${var.network_name}-nat-${each.key}"
  router                             = each.value.name
  region                             = each.value.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ── Firewall Rules ─────────────────────────────────────────────────────────────
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.this.self_link
  project = var.project_id

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [for s in values(var.subnets) : s.cidr]
  description   = "Allow internal traffic between subnets"
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = google_compute_network.this.self_link
  project = var.project_id

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  description   = "Allow Google Cloud health check probes"
}
