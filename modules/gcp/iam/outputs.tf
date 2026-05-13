output "service_account_emails" {
  description = "Map of service account name to email"
  value       = { for k, v in google_service_account.this : k => v.email }
}

output "service_account_ids" {
  description = "Map of service account name to ID"
  value       = { for k, v in google_service_account.this : k => v.id }
}
