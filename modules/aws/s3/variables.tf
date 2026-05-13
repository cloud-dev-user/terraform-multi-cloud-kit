variable "buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    versioning    = bool
    force_destroy = bool
    kms_key_id    = string
    event_bridge_enabled = bool
    lifecycle_rules = list(object({
      id      = string
      enabled = bool
      transitions = list(object({
        days          = number
        storage_class = string
      }))
      expiration_days                   = number
      noncurrent_version_expiration_days = number
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
