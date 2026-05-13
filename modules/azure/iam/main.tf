################################################################################
# Azure IAM Module
# ssktraining.dev — Terraform Multi-Cloud Kit
# Managed identities, role assignments, federated credentials for workload identity
################################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# ── User Assigned Managed Identities ──────────────────────────────────────────
resource "azurerm_user_assigned_identity" "this" {
  for_each = var.managed_identities

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# ── Role Assignments ───────────────────────────────────────────────────────────
resource "azurerm_role_assignment" "this" {
  for_each = {
    for pair in flatten([
      for identity_name, identity in var.managed_identities : [
        for assignment in identity.role_assignments : {
          key           = "${identity_name}__${assignment.role}__${assignment.scope}"
          identity_name = identity_name
          role          = assignment.role
          scope         = assignment.scope
        }
      ]
    ]) : pair.key => pair
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.this[each.value.identity_name].principal_id
}

# ── Federated Identity Credentials (Workload Identity for AKS) ────────────────
resource "azurerm_federated_identity_credential" "this" {
  for_each = {
    for pair in flatten([
      for identity_name, identity in var.managed_identities : [
        for fed in identity.federated_credentials : {
          key           = "${identity_name}__${fed.k8s_namespace}__${fed.k8s_service_account}"
          identity_name = identity_name
          issuer        = fed.oidc_issuer_url
          subject       = "system:serviceaccount:${fed.k8s_namespace}:${fed.k8s_service_account}"
          name          = "${identity_name}-${fed.k8s_namespace}-${fed.k8s_service_account}"
        }
      ]
    ]) : pair.key => pair
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this[each.value.identity_name].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = each.value.issuer
  subject             = each.value.subject
}
