# Scripts

Automation scripts for platform operations.

## Overview

| Script | Description |
|--------|-------------|
| `local-setup.nu` | Setup local KinD development environment |
| `bootstrap.nu` | Bootstrap management cluster |
| `platform.nu` | Platform orchestration CLI |

## Requirements

- [Nushell](https://www.nushell.sh/) >= 0.90
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [KinD](https://kind.sigs.k8s.io/) (for local development)
- [Terraform](https://www.terraform.io/) (for cloud deployments)

## Local Development

```bash
# Start local cluster with all components
nu scripts/local-setup.nu up

# Check status
nu scripts/local-setup.nu status

# Destroy local cluster
nu scripts/local-setup.nu down
```

## Platform CLI

```bash
# Create management cluster
nu scripts/platform.nu create --provider aws --env production

# Install platform components
nu scripts/platform.nu install --components argocd,crossplane,vault

# Destroy cluster
nu scripts/platform.nu destroy --provider aws
```

## Why Nushell?

- **Structured data**: Native JSON/YAML processing
- **Type-safe**: Parameters with types and defaults
- **Modern**: Better error handling than bash
- **Readable**: Clear syntax for complex operations
