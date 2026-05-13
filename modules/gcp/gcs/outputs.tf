output "bucket_names" {
  description = "Map of bucket key to bucket name"
  value       = { for k, v in google_storage_bucket.this : k => v.name }
}

output "bucket_urls" {
  description = "Map of bucket key to gs:// URL"
  value       = { for k, v in google_storage_bucket.this : k => v.url }
}

output "bucket_self_links" {
  description = "Map of bucket key to self link"
  value       = { for k, v in google_storage_bucket.this : k => v.self_link }
}
