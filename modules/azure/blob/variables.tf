variable "resource_group_name" { type = string }
variable "location"            { type = string }

variable "storage_accounts" {
  type = map(object({
    account_tier               = string
    replication_type           = string
    versioning                 = bool
    soft_delete_retention_days = number
    allowed_subnet_ids         = list(string)
    allowed_ips                = list(string)
    containers = list(object({
      name        = string
      access_type = string
    }))
    lifecycle_rules = list(object({
      name                     = string
      enabled                  = bool
      prefix_match             = list(string)
      tier_to_cool_after_days    = number
      tier_to_archive_after_days = number
      delete_after_days          = number
    }))
  }))
  default = {}
}

variable "tags" { type = map(string); default = {} }
