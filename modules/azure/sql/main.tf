################################################################################
# Azure SQL Module
# ssktraining.dev — Terraform Multi-Cloud Kit
################################################################################

terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm"; version = "~> 3.0" }
    random  = { source = "hashicorp/random";  version = "~> 3.0" }
  }
}

resource "random_password" "sql" {
  length  = 32
  special = true
  override_special = "!#$%&*-_=+?"
}

resource "azurerm_key_vault_secret" "sql_password" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = "${var.server_name}-sql-password"
  value        = random_password.sql.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_resource_group" "sql" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  resource_group_name          = azurerm_resource_group.sql.name
  location                     = azurerm_resource_group.sql.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = random_password.sql.result
  minimum_tls_version          = "1.2"
  tags                         = var.tags

  azuread_administrator {
    login_username = var.aad_admin_login
    object_id      = var.aad_admin_object_id
  }
}

resource "azurerm_mssql_database" "this" {
  for_each  = toset(var.databases)
  name      = each.value
  server_id = azurerm_mssql_server.this.id
  sku_name  = var.sku_name
  tags      = var.tags

  short_term_retention_policy {
    retention_days           = var.backup_retention_days
    backup_interval_in_hours = 12
  }

  long_term_retention_policy {
    weekly_retention  = "P4W"
    monthly_retention = "P12M"
    yearly_retention  = "P5Y"
    week_of_year      = 1
  }
}

resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_virtual_network_rule" "this" {
  for_each  = toset(var.allowed_subnet_ids)
  name      = "subnet-${index(var.allowed_subnet_ids, each.value)}"
  server_id = azurerm_mssql_server.this.id
  subnet_id = each.value
}
