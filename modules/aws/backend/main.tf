################################################################################
# AWS Remote State Backend Module
# ssktraining.dev — Terraform Multi-Cloud Kit
# S3 bucket + DynamoDB table for Terraform remote state with locking
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── S3 Bucket for State ────────────────────────────────────────────────────────
resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = merge(var.tags, { Name = var.bucket_name })
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.state_retention_days
    }
  }
}

# ── DynamoDB Lock Table ────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

  tags = merge(var.tags, { Name = var.dynamodb_table_name })
}

# ── Output the backend config block ───────────────────────────────────────────
# After running this module, paste the backend block into your root main.tf
# terraform {
#   backend "s3" {
#     bucket         = "<bucket_name>"
#     key            = "env/<env>/terraform.tfstate"
#     region         = "<region>"
#     dynamodb_table = "<table_name>"
#     encrypt        = true
#   }
# }
