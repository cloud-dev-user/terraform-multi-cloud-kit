variable "bucket_name" {
  description = "S3 bucket name for Terraform state (must be globally unique)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting state bucket and DynamoDB. Leave empty for AWS managed key."
  type        = string
  default     = ""
}

variable "state_retention_days" {
  description = "Days to retain old state file versions"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
