# Local Development Guide

This guide explains how to set up and use the local development environment.

## Overview

The local development environment uses [KinD](https://kind.sigs.k8s.io/) (Kubernetes in Docker) to run a fully-functional platform locally. This enables:

- Testing changes before pushing to production
- Developing new features without cloud costs
- Running the full platform stack locally

## Prerequisites

### Required

| Tool | Version | Installation |
|------|---------|--------------|
| Docker | >= 20.10 | [Docker Desktop](https://www.docker.com/products/docker-desktop) |
| kubectl | >= 1.28 | `brew install kubectl` |
| Helm | >= 3.12 | `brew install helm` |
| KinD | >= 0.20 | `brew install kind` |

### Optional (Recommended)

| Tool | Purpose | Installation |
|------|---------|--------------|
| Nushell | Enhanced scripts | `brew install nushell` |
| k9s | Terminal UI | `brew install k9s` |

### Check Dependencies

```bash
make deps
```

## Quick Start

### Start the Cluster

```bash
# Using Make (recommended)
make up

# Or using Nushell directly
nu scripts/local-setup.nu up
```

This will:
1. Create a KinD cluster named `agentic-dev`
2. Install NGINX Ingress Controller
3. Install ArgoCD
4. Install Crossplane
5. Install Vault (dev mode)
6. Install Kyverno

### Access Services

```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig-local.yaml

# Or use:
make kubeconfig
```

#### ArgoCD

- **URL**: https://localhost:30443 (or http://localhost:30080)
- **Username**: admin
- **Password**: `make argocd-password`

```bash
# Alternative: port-forward
make port-forward-argocd
# Then access: https://localhost:8080
```

#### Vault

- **URL**: http://localhost:8200 (via port-forward)
- **Token**: `root` (dev mode)

```bash
make port-forward-vault
```

#### Grafana (if monitoring installed)

- **URL**: http://localhost:30090
- **Username**: admin
- **Password**: prom-operator

```bash
# Install monitoring (optional, slow)
make install-monitoring
```

### Check Status

```bash
make status

# Or with Nushell
nu scripts/local-setup.nu status
```

### Stop the Cluster

```bash
make down
```

### Reset the Cluster

```bash
make reset  # Equivalent to: make down && make up
```

## Cluster Configuration

The KinD cluster is configured in `platform/bootstrap/kind-config.yaml`:

```yaml
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80        # HTTP ingress
      - containerPort: 443
        hostPort: 443       # HTTPS ingress
      - containerPort: 30000
        hostPort: 30000     # NodePort services
```

### Modifying the Configuration

1. Edit `platform/bootstrap/kind-config.yaml`
2. Reset the cluster: `make reset`

### Adding Worker Nodes

Uncomment the worker node lines in `kind-config.yaml`:

```yaml
nodes:
  - role: control-plane
    # ...
  - role: worker
  - role: worker
```

## Installing Individual Components

```bash
# Install specific components
make install-argocd
make install-crossplane
make install-vault
make install-kyverno
make install-monitoring  # Optional, takes longer

# Or via Nushell
nu scripts/local-setup.nu install --components argocd,crossplane
```

## Development Workflow

### 1. Make Changes

Edit files in the repository (apps/, policies/, crossplane/, etc.)

### 2. Apply Changes

```bash
# Apply Kubernetes manifests
kubectl apply -f apps/my-app.yaml

# Or let ArgoCD sync (if configured)
```

### 3. Test Changes

```bash
# Check resources
kubectl get all -n my-namespace

# Check ArgoCD sync status
kubectl get applications -n argocd

# Check Crossplane resources
kubectl get managed
```

### 4. Validate Before Commit

```bash
# Lint configurations
make lint

# Validate policies
make validate-policies

# Validate Crossplane
make validate-crossplane
```

## Troubleshooting

### Cluster Won't Start

```bash
# Check Docker is running
docker info

# Check for existing clusters
kind get clusters

# Delete and recreate
make reset
```

### Services Not Accessible

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check service endpoints
kubectl get svc -A

# Check port mappings
docker port agentic-dev-control-plane
```

### Out of Resources

```bash
# Check node resources
kubectl top nodes

# Check Docker resources
docker stats

# Increase Docker memory in Docker Desktop settings
```

### ArgoCD Not Syncing

```bash
# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force refresh
kubectl -n argocd patch application <app-name> \
  --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Reset Everything

```bash
# Nuclear option: delete everything
make down
docker system prune -f
make up
```

## Tips & Tricks

### Use k9s for Terminal UI

```bash
export KUBECONFIG=$(pwd)/kubeconfig-local.yaml
k9s
```

### Watch Resources

```bash
# Watch pods
kubectl get pods -A -w

# Watch ArgoCD applications
kubectl get applications -n argocd -w
```

### Quick ArgoCD Access

Add to your shell profile:

```bash
alias argocd-local='kubectl port-forward svc/argocd-server -n argocd 8080:443 &'
```

### Persist Data Between Restarts

KinD clusters are ephemeral. For persistent development:

1. Use ArgoCD to sync from your Git branch
2. Store test data in Git
3. Use `make reset` to get a clean state

## Resource Usage

The local cluster uses approximately:

| Component | CPU | Memory |
|-----------|-----|--------|
| KinD Node | 2 cores | 4 GB |
| ArgoCD | 0.5 cores | 512 MB |
| Crossplane | 0.2 cores | 256 MB |
| Vault | 0.1 cores | 128 MB |
| Kyverno | 0.2 cores | 256 MB |
| Monitoring | 1 core | 2 GB |

**Recommended**: At least 8 GB RAM allocated to Docker.
