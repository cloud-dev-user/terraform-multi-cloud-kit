variable "resource_group_name" { type = string }
variable "location"            { type = string }

variable "managed_identities" {
  description = "Map of managed identities to create"
  type = map(object({
    role_assignments = list(object({
      role  = string
      scope = string
    }))
    federated_credentials = list(object({
      oidc_issuer_url     = string
      k8s_namespace       = string
      k8s_service_account = string
    }))
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
