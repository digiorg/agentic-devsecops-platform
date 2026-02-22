# Scripts

Automation scripts for platform operations.

## Overview

| Script | Description |
|--------|-------------|
| `local-setup.nu` | Setup local KinD development environment |
| `bootstrap.nu` | Bootstrap management cluster (coming soon) |
| `platform.nu` | Platform orchestration CLI (coming soon) |

## Local Development

The `local-setup.nu` script manages the local KinD cluster for development.

### Commands

```bash
# Create cluster and install all components
nu scripts/local-setup.nu up

# Destroy cluster
nu scripts/local-setup.nu down

# Reset cluster (destroy + create)
nu scripts/local-setup.nu reset

# Show cluster status
nu scripts/local-setup.nu status

# Install specific components
nu scripts/local-setup.nu install --components argocd,crossplane
```

### What Gets Installed

| Component | Namespace | Access |
|-----------|-----------|--------|
| NGINX Ingress | ingress-nginx | Ports 80, 443 |
| ArgoCD | argocd | NodePort 30080/30443 |
| Crossplane | crossplane-system | — |
| Vault | vault | Port-forward 8200 |
| Kyverno | kyverno | — |

### Without Nushell

If you don't have Nushell installed, use Make:

```bash
make up      # Start cluster
make down    # Stop cluster
make status  # Check status
```

## Requirements

### Required

- [Nushell](https://www.nushell.sh/) >= 0.90 (or use Make fallback)
- [Docker](https://www.docker.com/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [KinD](https://kind.sigs.k8s.io/)

### Optional

- [Terraform](https://www.terraform.io/) (for cloud deployments)
- [kyverno CLI](https://kyverno.io/docs/kyverno-cli/) (for policy testing)
- [crossplane CLI](https://docs.crossplane.io/latest/cli/) (for XRD validation)

## Why Nushell?

Nushell provides several advantages over bash:

- **Structured data**: Native JSON/YAML processing
- **Type-safe**: Parameters with types and defaults
- **Modern**: Better error handling
- **Readable**: Clear syntax for complex operations

Example comparison:

```bash
# Bash: Parse JSON, extract field, handle errors
clusters=$(kind get clusters 2>/dev/null)
if echo "$clusters" | grep -q "agentic-dev"; then
    echo "Cluster exists"
fi

# Nushell: Same logic, cleaner syntax
let clusters = (kind get clusters | lines)
if "agentic-dev" in $clusters {
    print "Cluster exists"
}
```

## File Structure

```
scripts/
├── README.md           # This file
├── local-setup.nu      # Local development environment
├── bootstrap.nu        # Management cluster bootstrap (planned)
└── platform.nu         # Platform CLI (planned)
```

## Contributing

When adding new scripts:

1. Use Nushell for new scripts
2. Provide Make targets as fallback
3. Document all commands
4. Include prerequisite checks
5. Use colored output for status messages
