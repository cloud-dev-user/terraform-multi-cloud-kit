################################################################################
# AWS Complete Example
# ssktraining.dev — Terraform Multi-Cloud Kit
#
# Deploys: Remote backend + VPC + EKS + IAM
# Run this first to bootstrap state, then uncomment the backend block.
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── Uncomment after running the backend module once ──────────────────────────
  # backend "s3" {
  #   bucket         = "my-company-terraform-state"
  #   key            = "env/prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
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

# ── Step 0: Bootstrap Remote State ────────────────────────────────────────────
module "backend" {
  source = "../../modules/aws/backend"

  bucket_name         = "${var.project_name}-${local.env}-tf-state"
  dynamodb_table_name = "${var.project_name}-${local.env}-tf-lock"
  tags                = local.common_tags
}

# ── Step 1: VPC ────────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/aws/vpc"

  name               = local.name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  enable_nat_gateway = true
  single_nat_gateway = local.env == "prod" ? false : true
  enable_flow_logs   = true
  tags               = local.common_tags
}

# ── Step 2: EKS ────────────────────────────────────────────────────────────────
module "eks" {
  source = "../../modules/aws/eks"

  cluster_name       = local.name
  kubernetes_version = "1.29"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = var.allowed_cidr_blocks

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      labels         = { role = "system" }
      taints         = []
    }
    workload = {
      instance_types = local.env == "prod" ? ["m5.xlarge"] : ["t3.large"]
      capacity_type  = local.env == "prod" ? "ON_DEMAND" : "SPOT"
      desired_size   = 2
      min_size       = 1
      max_size       = 10
      labels         = { role = "workload" }
      taints         = []
    }
  }

  tags = local.common_tags
}
