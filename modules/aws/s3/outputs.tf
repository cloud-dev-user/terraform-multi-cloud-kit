output "bucket_ids" {
  description = "Map of bucket name to bucket ID"
  value       = { for k, v in aws_s3_bucket.this : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket name to ARN"
  value       = { for k, v in aws_s3_bucket.this : k => v.arn }
}

output "bucket_domain_names" {
  description = "Map of bucket name to domain name"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket_domain_name }
}
