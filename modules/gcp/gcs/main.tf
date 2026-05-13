################################################################################
# GCP Cloud Storage (GCS) Module
# ssktraining.dev — Terraform Multi-Cloud Kit
################################################################################

terraform {
  required_providers {
    google = { source = "hashicorp/google"; version = "~> 5.0" }
  }
}

resource "google_storage_bucket" "this" {
  for_each = var.buckets

  name          = each.key
  project       = var.project_id
  location      = each.value.location
  storage_class = each.value.storage_class
  force_destroy = each.value.force_destroy

  uniform_bucket_level_access = true

  versioning {
    enabled = each.value.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action { type = lifecycle_rule.value.action }
      condition {
        age                = lifecycle_rule.value.age
        matches_storage_class = lifecycle_rule.value.matches_storage_class
      }
    }
  }

  encryption {
    default_kms_key_name = each.value.kms_key_name
  }

  labels = var.labels
}

resource "google_storage_bucket_iam_member" "bindings" {
  for_each = {
    for pair in flatten([
      for bucket_name, bucket in var.buckets : [
        for binding in bucket.iam_bindings : {
          key         = "${bucket_name}__${binding.role}__${binding.member}"
          bucket_name = bucket_name
          role        = binding.role
          member      = binding.member
        }
      ]
    ]) : pair.key => pair
  }

  bucket = google_storage_bucket.this[each.value.bucket_name].name
  role   = each.value.role
  member = each.value.member
}
