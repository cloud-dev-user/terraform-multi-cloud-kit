################################################################################
# GCP Complete Example
# ssktraining.dev — Terraform Multi-Cloud Kit
#
# Deploys: VPC + GKE + IAM (Workload Identity) + Cloud SQL + GCS
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # backend "gcs" {
  #   bucket = "my-company-terraform-state"
  #   prefix = "env/prod"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  env  = var.environment
  name = "${var.project_name}-${local.env}"

  common_labels = {
    project     = var.project_name
    environment = local.env
    managed_by  = "terraform"
    source      = "shipstack-multi-cloud-kit"
  }
}

# ── VPC ────────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/gcp/vpc"

  project_id   = var.project_id
  network_name = local.name

  subnets = {
    "${local.name}-nodes" = {
      cidr   = "10.0.0.0/20"
      region = var.region
      secondary_ranges = {
        pods     = "10.48.0.0/14"
        services = "10.52.0.0/20"
      }
    }
  }

  enable_cloud_nat = true
  tags             = local.common_labels
}

# ── GKE ────────────────────────────────────────────────────────────────────────
module "gke" {
  source = "../../modules/gcp/gke"

  project_id   = var.project_id
  cluster_name = local.name
  location     = var.region
  network      = module.vpc.network_name
  subnetwork   = "${local.name}-nodes"

  pods_range_name     = "pods"
  services_range_name = "services"

  master_ipv4_cidr_block = "172.16.0.0/28"
  release_channel        = local.env == "prod" ? "STABLE" : "REGULAR"
  deletion_protection    = local.env == "prod"

  node_pools = {
    system = {
      machine_type       = "e2-standard-4"
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      spot               = false
      initial_node_count = 1
      min_node_count     = 1
      max_node_count     = 3
      labels             = { role = "system" }
      tags               = [local.name]
    }
    workload = {
      machine_type       = local.env == "prod" ? "n2-standard-4" : "e2-standard-2"
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      spot               = local.env != "prod"
      initial_node_count = 1
      min_node_count     = 1
      max_node_count     = 10
      labels             = { role = "workload" }
      tags               = [local.name]
    }
  }
}

# ── IAM ────────────────────────────────────────────────────────────────────────
module "iam" {
  source     = "../../modules/gcp/iam"
  project_id = var.project_id

  service_accounts = {
    "${local.name}-app" = {
      display_name = "Application service account"
      description  = "Used by application pods via Workload Identity"
      roles = [
        "roles/cloudsql.client",
        "roles/storage.objectAdmin",
        "roles/secretmanager.secretAccessor",
      ]
      workload_identity_bindings = [{
        k8s_namespace       = "default"
        k8s_service_account = "app-sa"
      }]
    }
  }
}

# ── Cloud SQL ──────────────────────────────────────────────────────────────────
module "cloudsql" {
  source = "../../modules/gcp/cloudsql"

  project_id      = var.project_id
  instance_name   = local.name
  region          = var.region
  database_version = "POSTGRES_15"
  tier            = local.env == "prod" ? "db-n1-standard-2" : "db-g1-small"
  high_availability = local.env == "prod"
  private_network = "projects/${var.project_id}/global/networks/${module.vpc.network_name}"
  deletion_protection = local.env == "prod"
  databases       = ["app_db"]
}

# ── GCS ────────────────────────────────────────────────────────────────────────
module "gcs" {
  source     = "../../modules/gcp/gcs"
  project_id = var.project_id
  labels     = local.common_labels

  buckets = {
    "${local.name}-assets" = {
      location      = "US"
      storage_class = "STANDARD"
      versioning    = true
      force_destroy = local.env != "prod"
      kms_key_name  = ""
      lifecycle_rules = [{
        action                = "SetStorageClass"
        age                   = 90
        matches_storage_class = ["STANDARD"]
      }]
      iam_bindings = [{
        role   = "roles/storage.objectAdmin"
        member = "serviceAccount:${module.iam.service_account_emails["${local.name}-app"]}"
      }]
    }
  }
}
