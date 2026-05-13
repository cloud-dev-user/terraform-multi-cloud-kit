################################################################################
# AWS IAM Module
# ssktraining.dev — Terraform Multi-Cloud Kit
# Reusable IAM roles with IRSA support, least-privilege policies
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Generic IAM Role with Trust Policy ────────────────────────────────────────
resource "aws_iam_role" "this" {
  for_each = var.roles

  name                 = each.key
  description          = each.value.description
  max_session_duration = each.value.max_session_duration
  path                 = each.value.path

  assume_role_policy = each.value.assume_role_policy

  tags = merge(var.tags, { Name = each.key })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for pair in flatten([
      for role_name, role in var.roles : [
        for policy_arn in role.managed_policy_arns : {
          key        = "${role_name}__${policy_arn}"
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "inline" {
  for_each = {
    for role_name, role in var.roles : role_name => role
    if role.inline_policy != ""
  }

  name   = "${each.key}-inline"
  role   = aws_iam_role.this[each.key].id
  policy = each.value.inline_policy
}

# ── IRSA Role (IAM Role for Service Account) ───────────────────────────────────
resource "aws_iam_role" "irsa" {
  for_each = var.irsa_roles

  name        = each.key
  description = "IRSA role for ${each.value.service_account_name} in ${each.value.namespace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = each.value.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(each.value.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
          "${replace(each.value.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name             = each.key
    ServiceAccount   = each.value.service_account_name
    Namespace        = each.value.namespace
  })
}

resource "aws_iam_role_policy_attachment" "irsa_managed" {
  for_each = {
    for pair in flatten([
      for role_name, role in var.irsa_roles : [
        for policy_arn in role.managed_policy_arns : {
          key        = "${role_name}__${policy_arn}"
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.irsa[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "irsa_inline" {
  for_each = {
    for role_name, role in var.irsa_roles : role_name => role
    if role.inline_policy != ""
  }

  name   = "${each.key}-inline"
  role   = aws_iam_role.irsa[each.key].id
  policy = each.value.inline_policy
}

# ── Instance Profile (for EC2 use cases) ──────────────────────────────────────
resource "aws_iam_instance_profile" "this" {
  for_each = { for k, v in var.roles : k => v if v.create_instance_profile }

  name = each.key
  role = aws_iam_role.this[each.key].name
  tags = var.tags
}
