# Platform Architecture

This document provides an overview of the Agentic DevSecOps Platform architecture.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Platform Architecture                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                       Industry Solutions Layer                          │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐  │
│  │  AI DevSecOps    │  │  Self-Service    │  │  Compliance          │  │
│  │  Workflows       │  │  Portal          │  │  Automation          │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────┤
│                     Business Integration Layer                          │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐  │
│  │  AI Agent        │  │  Policy          │  │  Tenant              │  │
│  │  Orchestration   │  │  Engine          │  │  Management          │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────┤
│                    Digital IT Foundation Layer                          │
│                                                                         │
│  ┌─────────────┬─────────────┬─────────────┬─────────────────────────┐ │
│  │   GitOps    │  Security   │ Observability│   Infrastructure      │ │
│  │             │             │              │                       │ │
│  │  • ArgoCD   │  • Kyverno  │  • Prometheus│  • Crossplane         │ │
│  │  • Flux     │  • Vault    │  • Grafana   │  • Terraform          │ │
│  │             │  • Falco    │  • Jaeger    │  • External Secrets   │ │
│  │             │  • Trivy    │  • Loki      │                       │ │
│  └─────────────┴─────────────┴─────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────┤
│                       Kubernetes Runtime Layer                          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │   AWS EKS  │  Azure AKS  │  GCP GKE  │  IONOS  │  StackIT      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Bootstrap Architecture

The platform uses a three-layer bootstrap architecture:

### Layer 1: Nushell Orchestration

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Nushell Orchestration                            │
│                                                                         │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐    │
│   │ platform.nu │    │local-setup.nu│   │     bootstrap.nu        │    │
│   │             │    │             │    │                         │    │
│   │ • create    │    │ • up        │    │ • install-argocd        │    │
│   │ • destroy   │    │ • down      │    │ • install-crossplane    │    │
│   │ • status    │    │ • reset     │    │ • install-vault         │    │
│   └─────────────┘    └─────────────┘    └─────────────────────────┘    │
│                                                                         │
│   Responsibilities:                                                     │
│   • Unified CLI interface                                               │
│   • Provider abstraction                                                │
│   • Workflow orchestration                                              │
│   • Configuration management                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

### Layer 2: Infrastructure as Code

```
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│        Terraform (Day-1)        │    │       Crossplane (Day-2)        │
│                                 │    │                                 │
│  Purpose:                       │    │  Purpose:                       │
│  • Initial cluster setup        │    │  • Ongoing infrastructure       │
│  • Bootstrap infrastructure     │    │  • Self-service resources       │
│                                 │    │                                 │
│  Resources:                     │    │  Resources:                     │
│  • Management cluster           │    │  • Workload clusters            │
│  • VPC/Network                  │    │  • Databases                    │
│  • IAM/Service accounts         │    │  • Storage buckets              │
│  • State backend                │    │  • Custom resources             │
│                                 │    │                                 │
│  State:                         │    │  State:                         │
│  • Remote backend (S3/GCS)      │    │  • Kubernetes etcd              │
│  • Explicit state locking       │    │  • GitOps (ArgoCD)              │
│                                 │    │                                 │
│  Reconciliation:                │    │  Reconciliation:                │
│  • Manual (terraform apply)     │    │  • Continuous (controller)      │
└─────────────────────────────────┘    └─────────────────────────────────┘
```

## Crossplane Multi-Cloud Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Platform Self-Service API                           │
│                                                                         │
│   ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌────────────┐ │
│   │ XDatabase     │ │ XCluster      │ │ XNetwork      │ │ XStorage   │ │
│   │ (Claim)       │ │ (Claim)       │ │ (Claim)       │ │ (Claim)    │ │
│   └───────┬───────┘ └───────┬───────┘ └───────┬───────┘ └─────┬──────┘ │
│           │                 │                 │               │        │
│           └─────────────────┴─────────────────┴───────────────┘        │
│                                     │                                   │
│                                     ▼                                   │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    Composite Resources (XR)                      │  │
│   │                                                                  │  │
│   │  XRD defines the API schema                                     │  │
│   │  Composition defines the implementation per provider            │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                     │                                   │
│           ┌─────────────────────────┼─────────────────────────┐        │
│           │                         │                         │        │
│           ▼                         ▼                         ▼        │
│   ┌───────────────┐         ┌───────────────┐         ┌─────────────┐ │
│   │ AWS           │         │ Azure         │         │ GCP         │ │
│   │ Composition   │         │ Composition   │         │ Composition │ │
│   │               │         │               │         │             │ │
│   │ • RDS         │         │ • Azure DB    │         │ • Cloud SQL │ │
│   │ • EKS         │         │ • AKS         │         │ • GKE       │ │
│   │ • S3          │         │ • Blob        │         │ • GCS       │ │
│   └───────┬───────┘         └───────┬───────┘         └──────┬──────┘ │
│           │                         │                        │        │
│           ▼                         ▼                        ▼        │
│   ┌───────────────┐         ┌───────────────┐         ┌─────────────┐ │
│   │ provider-aws  │         │provider-azure │         │ provider-gcp│ │
│   └───────────────┘         └───────────────┘         └─────────────┘ │
│           │                         │                        │        │
└───────────┼─────────────────────────┼────────────────────────┼────────┘
            │                         │                        │
            ▼                         ▼                        ▼
      ┌──────────┐             ┌──────────┐              ┌──────────┐
      │   AWS    │             │  Azure   │              │   GCP    │
      │  Cloud   │             │  Cloud   │              │  Cloud   │
      └──────────┘             └──────────┘              └──────────┘
```

## GitOps Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            GitOps Flow                                  │
└─────────────────────────────────────────────────────────────────────────┘

    Developer                    Git Repository                 Kubernetes
        │                              │                              │
        │  1. Push changes             │                              │
        ├─────────────────────────────▶│                              │
        │                              │                              │
        │                              │  2. ArgoCD detects change    │
        │                              │◀─────────────────────────────┤
        │                              │                              │
        │                              │  3. Sync to cluster          │
        │                              ├─────────────────────────────▶│
        │                              │                              │
        │                              │  4. Crossplane reconciles    │
        │                              │                              │
        │                              │         ┌────────────────────┤
        │                              │         │                    │
        │                              │         ▼                    │
        │                              │    ┌──────────┐              │
        │                              │    │  Cloud   │              │
        │                              │    │Resources │              │
        │                              │    └──────────┘              │
        │                              │                              │
        │  5. Status visible in Git    │                              │
        │◀─────────────────────────────┤                              │
        │                              │                              │
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Security Architecture                            │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          Policy Layer                                   │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                      Kyverno Policies                            │  │
│   │  • Pod Security Standards    • Image policies                   │  │
│   │  • Network policies          • Resource quotas                  │  │
│   │  • Label requirements        • RBAC enforcement                 │  │
│   └─────────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────┤
│                         Secrets Layer                                   │
│                                                                         │
│   ┌───────────────────┐    ┌───────────────────┐    ┌───────────────┐  │
│   │   HashiCorp       │───▶│ External Secrets  │───▶│  Kubernetes   │  │
│   │     Vault         │    │    Operator       │    │   Secrets     │  │
│   └───────────────────┘    └───────────────────┘    └───────────────┘  │
├─────────────────────────────────────────────────────────────────────────┤
│                         Network Layer                                   │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                   Network Policies                               │  │
│   │  • Default deny all                                             │  │
│   │  • Explicit allow rules                                         │  │
│   │  • Namespace isolation                                          │  │
│   └─────────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────┤
│                         Runtime Layer                                   │
│                                                                         │
│   ┌───────────────────┐    ┌───────────────────┐    ┌───────────────┐  │
│   │      Falco        │    │      Trivy        │    │   Pod Security│  │
│   │  (Runtime detect) │    │  (Vuln scanning)  │    │   Standards   │  │
│   └───────────────────┘    └───────────────────┘    └───────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Related ADRs

- [ADR-001: Bootstrap Framework Architecture](adr/001-bootstrap-framework-architecture.md)
