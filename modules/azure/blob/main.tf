################################################################################
# Azure Blob Storage Module
# ssktraining.dev — Terraform Multi-Cloud Kit
################################################################################

terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm"; version = "~> 3.0" }
  }
}

resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                     = each.key
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.replication_type
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true
  allow_nested_items_to_be_public = false
  tags                     = var.tags

  blob_properties {
    versioning_enabled = each.value.versioning
    delete_retention_policy {
      days = each.value.soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = each.value.soft_delete_retention_days
    }
  }

  dynamic "network_rules" {
    for_each = length(each.value.allowed_subnet_ids) > 0 || length(each.value.allowed_ips) > 0 ? [1] : []
    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = each.value.allowed_subnet_ids
      ip_rules                   = each.value.allowed_ips
      bypass                     = ["AzureServices", "Logging", "Metrics"]
    }
  }
}

resource "azurerm_storage_container" "this" {
  for_each = {
    for pair in flatten([
      for account_name, account in var.storage_accounts : [
        for container in account.containers : {
          key          = "${account_name}__${container.name}"
          account_name = account_name
          name         = container.name
          access_type  = container.access_type
        }
      ]
    ]) : pair.key => pair
  }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.this[each.value.account_name].name
  container_access_type = each.value.access_type
}

resource "azurerm_storage_management_policy" "this" {
  for_each = { for k, v in var.storage_accounts : k => v if length(v.lifecycle_rules) > 0 }

  storage_account_id = azurerm_storage_account.this[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        blob_types   = ["blockBlob"]
        prefix_match = rule.value.prefix_match
      }

      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
      }
    }
  }
}
