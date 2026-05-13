# Terraform Multi-Cloud Kit
### by [ssktraining.dev](https://ssktraining.dev)

> Production-grade Terraform modules for AWS, GCP, and Azure — built by a DevOps engineer who has run these in production, not generated from docs.

---

## What's Inside

18 battle-tested modules across 3 clouds. Drop them into any project and have a production-ready infrastructure baseline in hours, not weeks.

```
terraform-multi-cloud-kit/
├── modules/
│   ├── aws/
│   │   ├── vpc/          # VPC, subnets, NAT, flow logs
│   │   ├── eks/          # EKS cluster, node groups, IRSA, add-ons
│   │   ├── iam/          # Roles, policies, IRSA bindings
│   │   ├── rds/          # RDS with Multi-AZ, encryption, Secrets Manager
│   │   ├── s3/           # S3 with versioning, lifecycle, encryption
│   │   └── backend/      # Remote state: S3 + DynamoDB lock
│   ├── gcp/
│   │   ├── vpc/          # VPC, subnets, Cloud NAT, flow logs
│   │   ├── gke/          # GKE private cluster, Workload Identity, node pools
│   │   ├── iam/          # Service accounts, Workload Identity bindings
│   │   ├── cloudsql/     # Cloud SQL with private IP, HA, Secret Manager
│   │   └── gcs/          # GCS buckets with lifecycle, IAM bindings
│   └── azure/
│       ├── vnet/         # VNet, subnets, NSGs, NAT Gateway, flow logs
│       ├── aks/          # AKS with RBAC, managed identity, node pools
│       ├── iam/          # Managed identities, role assignments, federated creds
│       ├── sql/          # Azure SQL with AAD auth, VNet rules, Key Vault
│       └── blob/         # Storage accounts, containers, lifecycle policies
└── examples/
    ├── aws-complete/     # Full AWS stack: backend + VPC + EKS + IAM
    ├── gcp-complete/     # Full GCP stack: VPC + GKE + IAM + CloudSQL + GCS
    └── azure-complete/   # Full Azure stack: VNet + AKS + IAM + Blob
```

---

## Who This Is For

- **Platform / DevOps engineers** who need a reliable infra baseline fast
- **Startup CTOs** spinning up production environments without a full infra team
- **Consultants** who deliver the same foundational Terraform across multiple clients
- **Senior engineers** who know what "production-grade" actually means and don't want to write it from scratch again

---

## What "Production-Grade" Means Here

Every module ships with these defaults baked in — not as optional extras:

| Concern | What's included |
|---|---|
| **Encryption** | At-rest encryption on all storage, KMS-managed keys |
| **Least-privilege IAM** | Scoped roles, IRSA/Workload Identity for pod-level auth |
| **Network isolation** | Private subnets, NAT gateways, no public endpoints by default |
| **Observability** | Flow logs, CloudWatch/Cloud Logging/Azure Monitor wired up |
| **State management** | Remote backend with locking (S3+DynamoDB, GCS, AzureRM) |
| **Secrets** | Passwords never in tfvars — Secrets Manager / Key Vault / Secret Manager |
| **Multi-AZ / HA** | Configurable per env (save cost on dev, full HA on prod) |
| **Tagging / Labelling** | Consistent tags/labels propagated to every resource |

---

## Quickstart: AWS

**Step 1 — Bootstrap remote state (run once per account)**

```bash
cd examples/aws-complete
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_name, region, environment

terraform init
terraform apply -target=module.backend
```

**Step 2 — Uncomment the backend block in `main.tf`, then migrate state**

```bash
terraform init -migrate-state
```

**Step 3 — Deploy the full stack**

```bash
terraform apply
```

**Step 4 — Configure kubectl**

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
kubectl get nodes
```

---

## Quickstart: GCP

```bash
cd examples/gcp-complete
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

gcloud auth application-default login
terraform init
terraform apply
```

**Configure kubectl:**

```bash
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
kubectl get nodes
```

---

## Quickstart: Azure

```bash
cd examples/azure-complete
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

az login
terraform init
terraform apply
```

**Configure kubectl:**

```bash
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
kubectl get nodes
```

---

## Using Individual Modules

You don't have to use the complete examples. Every module is independently callable:

```hcl
# Just the AWS VPC, nothing else
module "vpc" {
  source = "github.com/your-org/terraform-multi-cloud-kit//modules/aws/vpc"

  name               = "myapp-prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  enable_nat_gateway = true
  single_nat_gateway = false   # true = cost saving for dev
  enable_flow_logs   = true

  tags = {
    Environment = "prod"
    Team        = "platform"
  }
}
```

```hcl
# EKS with IRSA, consuming the VPC above
module "eks" {
  source = "github.com/your-org/terraform-multi-cloud-kit//modules/aws/eks"

  cluster_name = "myapp-prod"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      min_size       = 2
      max_size       = 5
      labels         = { role = "system" }
      taints         = []
    }
  }

  tags = { Environment = "prod" }
}
```

---

## Module Reference

### AWS VPC (`modules/aws/vpc`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | Resource name prefix |
| `vpc_cidr` | string | `10.0.0.0/16` | VPC CIDR block |
| `availability_zones` | list(string) | required | AZs to deploy into |
| `enable_nat_gateway` | bool | `true` | Enable NAT for private subnets |
| `single_nat_gateway` | bool | `false` | One NAT (dev) vs one per AZ (prod) |
| `enable_flow_logs` | bool | `true` | VPC flow logs to CloudWatch |

**Outputs:** `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids`, `nat_gateway_ids`

---

### AWS EKS (`modules/aws/eks`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | required | EKS cluster name |
| `kubernetes_version` | string | `1.29` | K8s version |
| `vpc_id` | string | required | VPC to deploy into |
| `subnet_ids` | list(string) | required | Private subnet IDs |
| `node_groups` | map(object) | see vars | Node group configurations |
| `cluster_addons` | list(string) | coredns, kube-proxy, vpc-cni, ebs-csi | EKS add-ons |

**Outputs:** `cluster_name`, `cluster_endpoint`, `oidc_provider_arn`, `oidc_provider_url`

---

### AWS RDS (`modules/aws/rds`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `identifier` | string | required | RDS instance identifier |
| `engine` | string | `postgres` | Database engine |
| `engine_version` | string | `15.4` | Engine version |
| `instance_class` | string | `db.t3.medium` | Instance type |
| `multi_az` | bool | `true` | Multi-AZ deployment |
| `deletion_protection` | bool | `true` | Prevent accidental deletion |

> ⚠️ Password is auto-generated and stored in AWS Secrets Manager. Connection string is in the `db_secret_arn` output.

---

### GCP GKE (`modules/gcp/gke`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | required | GKE cluster name |
| `location` | string | required | Region (use region for HA) |
| `network` | string | required | VPC network name |
| `release_channel` | string | `REGULAR` | GKE release channel |
| `deletion_protection` | bool | `true` | Prevent accidental deletion |

> Workload Identity is always enabled. Shielded nodes always enabled.

---

### Azure AKS (`modules/azure/aks`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | required | AKS cluster name |
| `kubernetes_version` | string | `1.29` | K8s version |
| `sku_tier` | string | `Standard` | Free / Standard / Premium |
| `system_node_pool` | object | t3.medium equiv | System node pool config |

> AAD RBAC always enabled. Key Vault secrets provider always enabled.

---

## Environment Strategy

The examples are pre-wired for `dev`, `staging`, and `prod` environments with cost/reliability trade-offs built in:

| Setting | dev | staging | prod |
|---|---|---|---|
| NAT Gateways | 1 (shared) | 1 (shared) | 1 per AZ |
| Node capacity | SPOT | SPOT | ON_DEMAND |
| Multi-AZ DB | No | No | Yes |
| Deletion protection | No | No | Yes |
| Final DB snapshot | Skip | Skip | Enabled |

Switch environments by changing the `environment` variable:

```bash
terraform apply -var="environment=prod"
```

---

## Prerequisites

| Tool | Minimum Version |
|---|---|
| Terraform | >= 1.6.0 |
| AWS CLI | >= 2.0 (for AWS examples) |
| gcloud | >= 450.0 (for GCP examples) |
| Azure CLI | >= 2.50 (for Azure examples) |
| kubectl | >= 1.28 |

---

## FAQ

**Q: Can I use only the AWS modules and ignore GCP/Azure?**
Yes. Each cloud's modules are fully independent. Use only what you need.

**Q: Are these modules safe to use in production right now?**
Yes — with one caveat. Review the `terraform.tfvars.example` and tighten `allowed_cidr_blocks` for EKS public endpoint access before deploying to prod. Default is `0.0.0.0/0` for ease of initial setup.

**Q: Do I need to configure a backend before running the AWS example?**
Run `terraform apply -target=module.backend` first (with local state), then uncomment the backend block and run `terraform init -migrate-state`. The README walks you through this step by step.

**Q: Can I add more node pools after initial deployment?**
Yes. Add a new entry to the `node_groups` (AWS) or `node_pools` (GCP/Azure) map and `terraform apply`. Node pool scaling config ignores `desired_size` after first deploy (lifecycle rule included).

**Q: Where are database passwords stored?**
Never in tfvars or state in plaintext. AWS uses Secrets Manager, GCP uses Secret Manager, Azure uses Key Vault. The secret ARN/ID is in the module output — use that to retrieve the connection string at runtime.

---

## Support

Questions? Issues? Email **support@ssktraining.dev**

Found a bug or want a module added? Open an issue or email directly — this kit is actively maintained.

---

## License

Single-user license. You may use these modules across unlimited projects for a single individual or team within one company. Redistribution or resale of the source code is not permitted.

© ssktraining.dev
