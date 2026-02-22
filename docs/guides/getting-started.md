# Getting Started

This guide walks you through setting up the Agentic DevSecOps Platform.

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes CLI |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.12 | Package manager |
| [Terraform](https://www.terraform.io/downloads) | >= 1.5 | Infrastructure as Code |
| [Nushell](https://www.nushell.sh/book/installation.html) | >= 0.90 | Orchestration scripts |

### Optional Tools

| Tool | Purpose |
|------|---------|
| [KinD](https://kind.sigs.k8s.io/) | Local development |
| [kyverno CLI](https://kyverno.io/docs/kyverno-cli/) | Policy testing |
| [crossplane CLI](https://docs.crossplane.io/latest/cli/) | Crossplane management |

### Cloud Provider CLI (choose one or more)

| Provider | CLI | Installation |
|----------|-----|--------------|
| AWS | aws | `brew install awscli` |
| Azure | az | `brew install azure-cli` |
| GCP | gcloud | `brew install google-cloud-sdk` |
| IONOS | ionosctl | [IONOS CLI](https://docs.ionos.com/cli) |

## Quick Start (Local Development)

### 1. Clone the Repository

```bash
git clone https://github.com/digiorg/agentic-devsecops-platform.git
cd agentic-devsecops-platform
```

### 2. Start Local Cluster

```bash
# Using Make
make up

# Or using Nushell directly
nu scripts/local-setup.nu up
```

This creates a KinD cluster and installs:
- ArgoCD
- Crossplane
- Kyverno
- Vault (dev mode)

### 3. Access ArgoCD

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080
# Username: admin
```

### 4. Explore the Platform

```bash
# Check all components
kubectl get pods -A

# View ArgoCD applications
kubectl get applications -n argocd

# View Crossplane providers
kubectl get providers
```

### 5. Clean Up

```bash
make down
```

## Production Deployment

### 1. Configure Cloud Credentials

#### AWS

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="eu-central-1"
```

#### Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

#### GCP

```bash
gcloud auth login
gcloud config set project your-project-id
```

### 2. Configure Terraform Backend

Create `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "agentic-devsecops/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 3. Create Management Cluster

```bash
# Using Nushell
nu scripts/platform.nu create \
  --provider aws \
  --env production \
  --region eu-central-1 \
  --node-count 3 \
  --node-size medium

# Or using Terraform directly
cd terraform/modules/aws
terraform init
terraform apply -var="cluster_name=management" -var="environment=production"
```

### 4. Install Platform Components

```bash
nu scripts/bootstrap.nu install \
  --components argocd,crossplane,vault,kyverno,prometheus
```

### 5. Configure GitOps

1. Fork this repository
2. Update ArgoCD to point to your fork
3. Push changes to trigger sync

```bash
# Update ArgoCD repo URL
kubectl -n argocd patch application apps \
  --type merge \
  -p '{"spec":{"source":{"repoURL":"https://github.com/YOUR_ORG/agentic-devsecops-platform.git"}}}'
```

## Next Steps

- [Architecture Overview](../architecture.md)
- [Local Development Guide](./local-development.md)
- [Operations Guide](./operations.md)
- [Adding a New Cloud Provider](./adding-provider.md)

## Troubleshooting

### ArgoCD not syncing

```bash
# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force sync
kubectl -n argocd patch application <app-name> \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### Crossplane provider not ready

```bash
# Check provider status
kubectl get providers

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws
```

### Vault not unsealed

```bash
# Check Vault status
kubectl exec -n vault vault-0 -- vault status

# In dev mode, Vault auto-unseals
# In production, follow your unseal procedure
```
