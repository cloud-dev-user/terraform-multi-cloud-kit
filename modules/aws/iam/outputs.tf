output "role_arns" {
  description = "Map of role name to ARN"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of role name to name"
  value       = { for k, v in aws_iam_role.this : k => v.name }
}

output "irsa_role_arns" {
  description = "Map of IRSA role name to ARN"
  value       = { for k, v in aws_iam_role.irsa : k => v.arn }
}

output "instance_profile_names" {
  description = "Map of instance profile names"
  value       = { for k, v in aws_iam_instance_profile.this : k => v.name }
}
