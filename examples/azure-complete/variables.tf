variable "location" {
  description = "Azure region (e.g. eastus, westeurope, southeastasia)"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
