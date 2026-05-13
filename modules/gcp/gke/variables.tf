variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "location" {
  description = "Region or zone for the cluster (use region for regional cluster)"
  type        = string
}

variable "network" {
  description = "VPC network name or self link"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name or self link"
  type        = string
}

variable "pods_range_name" {
  description = "Secondary IP range name for pods"
  type        = string
}

variable "services_range_name" {
  description = "Secondary IP range name for services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR for the master nodes (e.g. 172.16.0.0/28)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_private_endpoint" {
  description = "Make master only accessible from private network"
  type        = bool
  default     = false
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for image verification"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection on the cluster"
  type        = bool
  default     = true
}

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    machine_type        = string
    disk_size_gb        = number
    disk_type           = string
    spot                = bool
    initial_node_count  = number
    min_node_count      = number
    max_node_count      = number
    labels              = map(string)
    tags                = list(string)
  }))
  default = {
    default = {
      machine_type       = "e2-standard-4"
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      spot               = false
      initial_node_count = 1
      min_node_count     = 1
      max_node_count     = 5
      labels             = {}
      tags               = []
    }
  }
}
