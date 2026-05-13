# Quick Reference — Terraform Multi-Cloud Kit

## Common Commands

```bash
# Init
terraform init

# Plan (always before apply)
terraform plan -out=tfplan

# Apply from plan
terraform apply tfplan

# Target a single module
terraform apply -target=module.vpc

# Destroy (careful in prod)
terraform destroy

# Format all files
terraform fmt -recursive

# Validate
terraform validate
```

---

## First-Time AWS Setup (5 minutes)

```bash
# 1. Configure AWS credentials
aws configure
# or: export AWS_PROFILE=myprofile

# 2. Copy and edit vars
cd examples/aws-complete
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # set project_name, environment

# 3. Bootstrap state backend
terraform init
terraform apply -target=module.backend

# 4. Uncomment backend block in main.tf, migrate state
terraform init -migrate-state

# 5. Full deploy
terraform apply

# 6. Connect to cluster
aws eks update-kubeconfig --name <project>-<env> --region us-east-1
kubectl get nodes
```

---

## First-Time GCP Setup (5 minutes)

```bash
# 1. Authenticate
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# 2. Enable required APIs
gcloud services enable \
  container.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  compute.googleapis.com

# 3. Deploy
cd examples/gcp-complete
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# 4. Connect to cluster
gcloud container clusters get-credentials <name> --region <region>
kubectl get nodes
```

---

## First-Time Azure Setup (5 minutes)

```bash
# 1. Authenticate
az login
az account set --subscription YOUR_SUBSCRIPTION_ID

# 2. Register providers (if new subscription)
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Sql

# 3. Deploy
cd examples/azure-complete
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# 4. Connect to cluster
az aks get-credentials --resource-group <name>-<env>-aks-rg --name <name>-<env>
kubectl get nodes
```

---

## Retrieving Database Credentials

**AWS — Secrets Manager:**
```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_secret_arn) \
  --query SecretString --output text | jq .
```

**GCP — Secret Manager:**
```bash
gcloud secrets versions access latest \
  --secret=$(terraform output -raw db_secret_id)
```

**Azure — Key Vault:**
```bash
az keyvault secret show \
  --vault-name <vault-name> \
  --name <server-name>-sql-password \
  --query value -o tsv
```

---

## Switching Environments

```bash
# Dev (default)
terraform apply -var="environment=dev"

# Production — enables Multi-AZ, deletion protection, per-AZ NAT
terraform apply -var="environment=prod"
```

Or use separate var files:

```bash
terraform apply -var-file="envs/prod.tfvars"
```

---

## IRSA / Workload Identity Setup (Post-Cluster)

**AWS — Annotate the K8s service account:**
```bash
kubectl annotate serviceaccount app-sa \
  -n default \
  eks.amazonaws.com/role-arn=$(terraform output -raw irsa_role_arn)
```

**GCP — Annotate the K8s service account:**
```bash
kubectl annotate serviceaccount app-sa \
  -n default \
  iam.gke.io/gcp-service-account=$(terraform output -raw sa_email)
```

**Azure — Annotate the K8s service account:**
```bash
kubectl annotate serviceaccount app-sa \
  -n default \
  azure.workload.identity/client-id=$(terraform output -raw identity_client_id)
```

---

## Cost Estimates (rough monthly, us-east-1 / us-central1)

| Component | Dev | Prod |
|---|---|---|
| EKS/GKE/AKS cluster | ~$75 | ~$75 |
| 2x t3.medium nodes (SPOT) | ~$20 | — |
| 2x m5.xlarge nodes (ON_DEMAND) | — | ~$280 |
| RDS db.t3.medium (single-AZ) | ~$30 | — |
| RDS db.t3.medium (Multi-AZ) | — | ~$60 |
| NAT Gateway (1x) | ~$35 | — |
| NAT Gateway (3x) | — | ~$105 |
| **Total estimate** | **~$160/mo** | **~$520/mo** |

> These are rough estimates. Always run `terraform plan` and check AWS/GCP/Azure cost calculators for exact numbers before deploying to prod.

---

## Troubleshooting

**`Error: configuring Terraform AWS Provider: no valid credential sources`**
→ Run `aws configure` or set `AWS_PROFILE` environment variable.

**`Error: google: could not find default credentials`**
→ Run `gcloud auth application-default login`.

**`Error: The subscription is not registered to use namespace 'Microsoft.ContainerService'`**
→ Run `az provider register --namespace Microsoft.ContainerService` and wait ~2 minutes.

**EKS nodes not joining:**
→ Check that `subnet_ids` are private subnets, not public. EKS managed nodes must be in private subnets.

**GKE cluster stuck in PROVISIONING:**
→ Usually a quota issue. Check `gcloud compute project-info describe --project=PROJECT_ID` for CPU quota.

**`Error acquiring the state lock` (DynamoDB):**
→ Another apply is running, or a previous apply crashed. Force-unlock with:
```bash
terraform force-unlock LOCK_ID
```

---

*ssktraining.dev — Build once, ship everywhere.*
