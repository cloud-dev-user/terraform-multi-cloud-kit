variable "resource_group_name" {
  description = "Resource group for the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "sku_tier" {
  description = "AKS SKU tier: Free, Standard, or Premium"
  type        = string
  default     = "Standard"
}

variable "subnet_id" {
  description = "Subnet ID for node pools"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "system_node_pool" {
  description = "System node pool configuration"
  type = object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    os_disk_size_gb     = number
  })
  default = {
    vm_size             = "Standard_D2s_v3"
    node_count          = 2
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    os_disk_size_gb     = 128
  }
}

variable "additional_node_pools" {
  description = "Map of additional node pools"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    spot                = bool
    node_labels         = map(string)
    node_taints         = list(string)
  }))
  default = {}
}

variable "enable_monitoring" {
  description = "Enable OMS agent for Azure Monitor"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
