# Platform

This directory contains the platform infrastructure configurations.

## Structure

```
platform/
├── bootstrap/     # Scripts and configs for initial cluster setup
└── base/          # Base Kustomize configurations
    ├── argocd/    # ArgoCD Helm values and configs
    ├── kyverno/   # Kyverno Helm values and configs
    ├── vault/     # Vault Helm values and configs
    └── crossplane/# Crossplane base configuration
```

## Bootstrap

The `bootstrap/` directory contains scripts for initial cluster provisioning:

- Management cluster creation (via Terraform)
- Platform components installation
- Initial GitOps setup

## Base Configurations

The `base/` directory uses Kustomize for configuration management. Each component has:

- `values.yaml` - Helm values
- `kustomization.yaml` - Kustomize config
- Component-specific configurations

## Usage

See the main README for detailed setup instructions.
