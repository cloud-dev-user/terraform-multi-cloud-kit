variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "buckets" {
  description = "Map of GCS buckets to create"
  type = map(object({
    location      = string
    storage_class = string
    versioning    = bool
    force_destroy = bool
    kms_key_name  = string
    lifecycle_rules = list(object({
      action                = string
      age                   = number
      matches_storage_class = list(string)
    }))
    iam_bindings = list(object({
      role   = string
      member = string
    }))
  }))
  default = {}
}

variable "labels" {
  description = "Labels to apply to all buckets"
  type        = map(string)
  default     = {}
}
