output "identity_ids" {
  description = "Map of identity name to resource ID"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.id }
}

output "identity_principal_ids" {
  description = "Map of identity name to principal ID (for RBAC)"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.principal_id }
}

output "identity_client_ids" {
  description = "Map of identity name to client ID (for workload identity annotation)"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.client_id }
}
