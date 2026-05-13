output "storage_account_ids" {
  value = { for k, v in azurerm_storage_account.this : k => v.id }
}
output "primary_endpoints" {
  value = { for k, v in azurerm_storage_account.this : k => v.primary_blob_endpoint }
}
output "primary_connection_strings" {
  value     = { for k, v in azurerm_storage_account.this : k => v.primary_connection_string }
  sensitive = true
}
