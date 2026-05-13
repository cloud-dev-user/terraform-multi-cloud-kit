################################################################################
# Azure Complete Example
# ssktraining.dev — Terraform Multi-Cloud Kit
#
# Deploys: VNet + AKS + IAM (Workload Identity) + Azure SQL + Blob Storage
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # backend "azurerm" {
  #   resource_group_name  = "my-tf-state-rg"
  #   storage_account_name = "mycompanytfstate"
  #   container_name       = "tfstate"
  #   key                  = "env/prod/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  env  = var.environment
  name = "${var.project_name}-${local.env}"

  common_tags = {
    Project     = var.project_name
    Environment = local.env
    ManagedBy   = "Terraform"
    Source      = "ShipStack-Multi-Cloud-Kit"
  }
}

# ── VNet ───────────────────────────────────────────────────────────────────────
module "vnet" {
  source = "../../modules/azure/vnet"

  resource_group_name = "${local.name}-network-rg"
  location            = var.location
  vnet_name           = local.name
  address_space       = ["10.0.0.0/16"]
  enable_nat_gateway  = true
  enable_flow_logs    = true
  tags                = local.common_tags

  subnets = {
    aks-nodes = {
      cidr               = "10.0.0.0/22"
      service_endpoints  = ["Microsoft.Sql", "Microsoft.Storage"]
      attach_nat_gateway = true
      delegation         = null
      nsg_rules          = []
    }
    private-endpoints = {
      cidr               = "10.0.4.0/24"
      service_endpoints  = []
      attach_nat_gateway = false
      delegation         = null
      nsg_rules          = []
    }
  }
}

# ── AKS ────────────────────────────────────────────────────────────────────────
module "aks" {
  source = "../../modules/azure/aks"

  resource_group_name = "${local.name}-aks-rg"
  location            = var.location
  cluster_name        = local.name
  dns_prefix          = local.name
  kubernetes_version  = "1.29"
  sku_tier            = local.env == "prod" ? "Standard" : "Free"
  subnet_id           = module.vnet.subnet_ids["aks-nodes"]
  enable_monitoring   = true
  tags                = local.common_tags

  system_node_pool = {
    vm_size             = "Standard_D2s_v3"
    node_count          = 2
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    os_disk_size_gb     = 128
  }

  additional_node_pools = local.env == "prod" ? {
    workload = {
      vm_size             = "Standard_D4s_v3"
      node_count          = 2
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 20
      spot                = false
      node_labels         = { role = "workload" }
      node_taints         = []
    }
  } : {}
}

# ── IAM ────────────────────────────────────────────────────────────────────────
module "iam" {
  source              = "../../modules/azure/iam"
  resource_group_name = "${local.name}-aks-rg"
  location            = var.location
  tags                = local.common_tags

  managed_identities = {
    "${local.name}-app" = {
      role_assignments = [
        {
          role  = "Storage Blob Data Contributor"
          scope = module.blob.storage_account_ids["${replace(local.name, "-", "")}assets"]
        }
      ]
      federated_credentials = [{
        oidc_issuer_url     = module.aks.oidc_issuer_url
        k8s_namespace       = "default"
        k8s_service_account = "app-sa"
      }]
    }
  }

  depends_on = [module.aks, module.blob]
}

# ── Blob Storage ───────────────────────────────────────────────────────────────
module "blob" {
  source              = "../../modules/azure/blob"
  resource_group_name = "${local.name}-storage-rg"
  location            = var.location
  tags                = local.common_tags

  storage_accounts = {
    "${replace(local.name, "-", "")}assets" = {
      account_tier               = "Standard"
      replication_type           = local.env == "prod" ? "GRS" : "LRS"
      versioning                 = true
      soft_delete_retention_days = 7
      allowed_subnet_ids         = [module.vnet.subnet_ids["aks-nodes"]]
      allowed_ips                = []
      containers = [{
        name        = "uploads"
        access_type = "private"
      }]
      lifecycle_rules = [{
        name                     = "archive-old"
        enabled                  = true
        prefix_match             = []
        tier_to_cool_after_days    = 30
        tier_to_archive_after_days = 90
        delete_after_days          = 0
      }]
    }
  }
}
