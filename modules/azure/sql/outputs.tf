output "server_id"   { value = azurerm_mssql_server.this.id }
output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
output "database_ids" {
  value = { for k, v in azurerm_mssql_database.this : k => v.id }
}
