variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name for the VPC network"
  type        = string
}

variable "subnets" {
  description = "Map of subnet configs"
  type = map(object({
    cidr             = string
    region           = string
    secondary_ranges = map(string)
  }))
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for private instances"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
