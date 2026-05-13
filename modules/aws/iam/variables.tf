variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    description              = string
    assume_role_policy       = string
    managed_policy_arns      = list(string)
    inline_policy            = string
    path                     = string
    max_session_duration     = number
    create_instance_profile  = bool
  }))
  default = {}
}

variable "irsa_roles" {
  description = "Map of IRSA roles to create (IAM Roles for Service Accounts)"
  type = map(object({
    service_account_name = string
    namespace            = string
    oidc_provider_arn    = string
    oidc_provider_url    = string
    managed_policy_arns  = list(string)
    inline_policy        = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
