variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_accounts" {
  description = "Map of service accounts to create"
  type = map(object({
    display_name = string
    description  = string
    roles        = list(string)
    workload_identity_bindings = list(object({
      k8s_namespace       = string
      k8s_service_account = string
    }))
  }))
  default = {}
}

variable "custom_roles" {
  description = "Map of custom IAM roles to create"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
  }))
  default = {}
}
