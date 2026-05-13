################################################################################
# Azure AKS Module
# ssktraining.dev — Terraform Multi-Cloud Kit
# Production-grade AKS cluster with RBAC, managed identity, node pools
################################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# ── Resource Group ─────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ── Managed Identity ───────────────────────────────────────────────────────────
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  tags                = var.tags
}

# ── Log Analytics Workspace ────────────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# ── AKS Cluster ────────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  sku_tier = var.sku_tier

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_pool.node_count
    vm_size             = var.system_node_pool.vm_size
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = var.system_node_pool.enable_auto_scaling
    min_count           = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.min_count : null
    max_count           = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.max_count : null
    os_disk_size_gb     = var.system_node_pool.os_disk_size_gb
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    zones               = var.availability_zones

    node_labels = {
      "role" = "system"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
    max_graceful_termination_sec = "600"
  }

  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [2, 3, 4]
    }
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }
}

# ── Additional Node Pools ──────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  vnet_subnet_id        = var.subnet_id
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  priority              = each.value.spot ? "Spot" : "Regular"
  eviction_policy       = each.value.spot ? "Delete" : null
  zones                 = var.availability_zones

  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  tags = var.tags
}
