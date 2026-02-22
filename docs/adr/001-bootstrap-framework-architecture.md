# ADR-001: Bootstrap Framework Architecture

**Status:** Accepted  
**Date:** 2026-02-22  
**Deciders:** @christian.mueller, @simon-itstudio  

## Context

The Agentic DevSecOps Platform needs a consistent, repeatable way to:

1. Provision Kubernetes clusters across multiple cloud providers (AWS, Azure, GCP, IONOS, StackIT)
2. Install and configure platform components (ArgoCD, Crossplane, Vault, Kyverno)
3. Manage infrastructure lifecycle with GitOps principles
4. Support both initial setup (Day-1) and ongoing operations (Day-2)

We need to decide on the tooling and architecture for this bootstrap process.

## Decision

We adopt a **three-layer architecture** combining Terraform, Crossplane, and Nushell:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Nushell Orchestration                           │
│                    (platform.nu / local-setup.nu)                       │
│         Unified CLI interface for all bootstrap operations              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────┐  ┌─────────────────────────────────┐  │
│  │      Terraform (Day-1)      │  │      Crossplane (Day-2)         │  │
│  │                             │  │                                 │  │
│  │  • Management cluster       │  │  • Workload clusters            │  │
│  │  • Initial VPC/Network      │  │  • Databases                    │  │
│  │  • IAM/Service Accounts     │  │  • Storage                      │  │
│  │  • Bootstrap resources      │  │  • Additional infrastructure    │  │
│  │                             │  │  • Self-service resources       │  │
│  │  State: Remote Backend      │  │  State: Kubernetes etcd         │  │
│  │  Reconcile: Manual          │  │  Reconcile: Continuous          │  │
│  └─────────────────────────────┘  └─────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Layer 1: Nushell Orchestration

Nushell serves as the orchestration layer providing:

- **Unified CLI**: Single entry point for all operations
- **Provider Abstraction**: Common interface across cloud providers
- **Workflow Automation**: Sequencing of Terraform and Kubectl commands
- **Configuration Management**: Environment-specific settings

```nu
# Example: Bootstrap management cluster
def "main create" [
    --provider: string    # aws, azure, gcp, ionos
    --env: string         # dev, staging, production
    --region: string      # Cloud region
] {
    # 1. Run Terraform for management cluster
    terraform_apply $provider $env $region
    
    # 2. Configure kubeconfig
    configure_kubeconfig $provider
    
    # 3. Install platform components via Helm/ArgoCD
    install_platform_components
    
    # 4. Configure Crossplane providers
    configure_crossplane $provider
}
```

### Layer 2: Terraform (Day-1 Operations)

Terraform handles **initial infrastructure provisioning**:

| Resource | Description |
|----------|-------------|
| Management Cluster | The primary Kubernetes cluster hosting the platform |
| VPC/Network | Cloud networking (VPCs, subnets, security groups) |
| IAM | Service accounts, roles, policies for platform components |
| State Backend | S3/GCS bucket for Terraform state |

**State Management:**
- Remote backend (S3, GCS, Azure Blob)
- State locking via DynamoDB/GCS
- Separate state per environment

### Layer 3: Crossplane (Day-2 Operations)

Crossplane handles **ongoing infrastructure management**:

| Resource | Description |
|----------|-------------|
| Workload Clusters | Additional Kubernetes clusters |
| Databases | RDS, Cloud SQL, Azure Database |
| Storage | S3 buckets, GCS, Azure Blob |
| Custom Resources | Platform-specific infrastructure |

**Benefits:**
- GitOps-native (stored in Git, synced by ArgoCD)
- Kubernetes-native API (kubectl apply)
- Continuous reconciliation (self-healing)
- Multi-tenancy via namespaces

## Bootstrap Sequence

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Bootstrap Sequence                             │
└──────────────────────────────────────────────────────────────────────┘

Phase 1: Infrastructure (Terraform)
┌─────────────────────────────────────────────────────────────────────┐
│  1. Create state backend (S3/GCS)                                   │
│  2. Create VPC/Network                                              │
│  3. Create IAM roles/service accounts                               │
│  4. Create management Kubernetes cluster                            │
│  5. Output kubeconfig                                               │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
Phase 2: Platform Components (Helm/ArgoCD)
┌─────────────────────────────────────────────────────────────────────┐
│  1. Install ArgoCD                                                  │
│  2. Install Crossplane                                              │
│  3. Install Vault + External Secrets                                │
│  4. Install Kyverno                                                 │
│  5. Install Observability Stack (Prometheus, Grafana, Loki)         │
│  6. Configure App-of-Apps                                           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
Phase 3: Crossplane Setup
┌─────────────────────────────────────────────────────────────────────┐
│  1. Install Crossplane Providers (AWS, Azure, GCP, etc.)            │
│  2. Configure ProviderConfigs with credentials                      │
│  3. Deploy XRDs (Composite Resource Definitions)                    │
│  4. Deploy Compositions per provider                                │
│  5. Platform ready for self-service                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Provider Abstraction Pattern

Each cloud provider implements a common interface:

```
terraform/modules/
├── aws/
│   ├── main.tf
│   ├── variables.tf      # Standard interface
│   ├── outputs.tf        # Standard outputs
│   └── versions.tf
├── azure/
│   ├── main.tf
│   ├── variables.tf      # Same interface
│   ├── outputs.tf        # Same outputs
│   └── versions.tf
└── ...
```

### Standard Variables (All Providers)

```hcl
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "region" {
  description = "Cloud provider region"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "node_size" {
  description = "Node size category"
  type        = string
  default     = "small"  # small, medium, large
  
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size)
    error_message = "node_size must be small, medium, or large"
  }
}
```

### Standard Outputs (All Providers)

```hcl
output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64)"
}

output "kubeconfig" {
  description = "Kubeconfig for cluster access"
  sensitive   = true
}
```

### Node Size Mapping

| Size | AWS | Azure | GCP | IONOS |
|------|-----|-------|-----|-------|
| small | t3.medium | Standard_B2s | e2-standard-2 | 2C-4GB |
| medium | t3.xlarge | Standard_B4ms | e2-standard-4 | 4C-8GB |
| large | t3.2xlarge | Standard_B8ms | e2-standard-8 | 8C-32GB |

## Consequences

### Positive

- **Clear separation of concerns**: Terraform for bootstrap, Crossplane for Day-2
- **GitOps-native**: All Crossplane resources in Git, synced by ArgoCD
- **Self-service**: Platform users can provision resources via kubectl
- **Provider flexibility**: Easy to add new cloud providers
- **Unified interface**: Nushell provides consistent UX across providers

### Negative

- **Learning curve**: Teams need to learn three tools (Terraform, Crossplane, Nushell)
- **Complexity**: More moving parts than a single-tool solution
- **Coordination**: Need to manage handoff between Terraform and Crossplane

### Neutral

- Terraform state needs separate backup/DR strategy
- Crossplane provider credentials managed via External Secrets

## Alternatives Considered

### Alternative 1: Terraform Only

Use Terraform for all infrastructure management.

**Pros:**
- Single tool, simpler mental model
- Mature ecosystem

**Cons:**
- No continuous reconciliation (drift detection requires manual runs)
- Not GitOps-native (requires Terraform Cloud or Atlantis)
- Harder to enable self-service

**Why not chosen:** Doesn't align with GitOps-first philosophy and lacks continuous reconciliation.

### Alternative 2: Crossplane Only

Use Crossplane for everything, including initial cluster creation.

**Pros:**
- Single tool for all infrastructure
- Fully GitOps-native

**Cons:**
- Chicken-and-egg: Need a cluster to run Crossplane
- More complex initial bootstrap
- State management in Kubernetes can be problematic for core infrastructure

**Why not chosen:** Bootstrap complexity and risk of losing critical state if cluster fails.

### Alternative 3: Pulumi

Use Pulumi instead of Terraform for programmatic IaC.

**Pros:**
- Real programming languages (TypeScript, Python, Go)
- Better testing capabilities

**Cons:**
- Smaller community than Terraform
- Less provider coverage
- Team familiarity with Terraform

**Why not chosen:** Terraform's ecosystem and team familiarity outweigh Pulumi's benefits.

## References

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GitOps Principles](https://opengitops.dev/)
- [Nushell Documentation](https://www.nushell.sh/book/)
