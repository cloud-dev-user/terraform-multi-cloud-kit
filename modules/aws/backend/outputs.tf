output "bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.state.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.state.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.lock.name
}

output "backend_config" {
  description = "Paste this into your root module's terraform block"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state.bucket}"
        key            = "env/<ENV>/terraform.tfstate"
        region         = "${aws_s3_bucket.state.region}"
        dynamodb_table = "${aws_dynamodb_table.lock.name}"
        encrypt        = true
      }
    }
  EOT
}
