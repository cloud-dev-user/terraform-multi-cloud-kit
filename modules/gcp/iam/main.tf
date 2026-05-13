################################################################################
# GCP IAM Module
# ssktraining.dev — Terraform Multi-Cloud Kit
# Service accounts, Workload Identity bindings, project IAM members
################################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ── Service Accounts ───────────────────────────────────────────────────────────
resource "google_service_account" "this" {
  for_each = var.service_accounts

  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# ── Project IAM Bindings ───────────────────────────────────────────────────────
resource "google_project_iam_member" "sa_roles" {
  for_each = {
    for pair in flatten([
      for sa_name, sa in var.service_accounts : [
        for role in sa.roles : {
          key     = "${sa_name}__${role}"
          sa_name = sa_name
          role    = role
        }
      ]
    ]) : pair.key => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.this[each.value.sa_name].email}"
}

# ── Workload Identity Bindings ─────────────────────────────────────────────────
resource "google_service_account_iam_member" "workload_identity" {
  for_each = {
    for pair in flatten([
      for sa_name, sa in var.service_accounts : [
        for wi in sa.workload_identity_bindings : {
          key            = "${sa_name}__${wi.k8s_namespace}__${wi.k8s_service_account}"
          sa_name        = sa_name
          k8s_namespace  = wi.k8s_namespace
          k8s_sa         = wi.k8s_service_account
        }
      ]
    ]) : pair.key => pair
  }

  service_account_id = google_service_account.this[each.value.sa_name].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.k8s_namespace}/${each.value.k8s_sa}]"
}

# ── Custom Roles ───────────────────────────────────────────────────────────────
resource "google_project_iam_custom_role" "this" {
  for_each = var.custom_roles

  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  project     = var.project_id
}
