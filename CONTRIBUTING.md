# Contributing to Agentic DevSecOps Platform

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## 🚀 Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/agentic-devsecops-platform.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Submit a Pull Request

## 📁 Project Structure

```
agentic-devsecops-platform/
├── platform/
│   ├── bootstrap/           # Cluster bootstrapping scripts
│   └── base/                # Base Kustomize configurations
│       ├── argocd/          # ArgoCD configuration
│       ├── kyverno/         # Kyverno configuration
│       ├── vault/           # Vault configuration
│       └── crossplane/      # Crossplane base setup
├── apps/                    # ArgoCD Application manifests
├── policies/
│   └── kyverno/             # Kyverno policies
│       ├── cluster-policies/
│       └── policies/
├── crossplane/
│   ├── xrds/                # Composite Resource Definitions
│   ├── compositions/        # Compositions per provider
│   └── providers/           # Provider configurations
├── terraform/
│   └── modules/             # Terraform modules per provider
│       ├── aws/
│       ├── azure/
│       ├── gcp/
│       └── ionos/
├── docs/
│   ├── adr/                 # Architecture Decision Records
│   └── guides/              # User guides
└── scripts/                 # Automation scripts
```

## 🔀 Git Workflow

### Branch Naming

- `feature/<issue-number>-<short-description>` - New features
- `fix/<issue-number>-<short-description>` - Bug fixes
- `docs/<short-description>` - Documentation changes
- `refactor/<short-description>` - Code refactoring

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```
feat(crossplane): Add XRD for CompositeDatabase
fix(argocd): Correct RBAC permissions for app-of-apps
docs(readme): Update architecture diagram
```

### Pull Request Process

1. Ensure your PR references an issue (e.g., "Closes #5")
2. Update documentation if needed
3. Add/update tests where applicable
4. Request review from maintainers
5. Address review feedback
6. Squash commits before merge (if requested)

## 📝 Coding Standards

### YAML Files (Kubernetes/Helm/ArgoCD)

- Use 2-space indentation
- Include comments for non-obvious configurations
- Use explicit `apiVersion` and `kind`
- Follow Kubernetes naming conventions (lowercase, dashes)

### Terraform

- Use 2-space indentation
- Include `description` for all variables
- Use meaningful resource names
- Add `tags` to all resources
- Include example `.tfvars` files

### Kyverno Policies

- Include `metadata.annotations` with:
  - `policies.kyverno.io/title`
  - `policies.kyverno.io/description`
  - `policies.kyverno.io/severity`
- Test policies locally before submitting

### Crossplane XRDs/Compositions

- Use clear naming: `x<resource>s.platform.digiorg.io`
- Include JSON Schema validation in XRDs
- Document all spec fields
- Provide example claims

## 🧪 Testing

### Local Testing with KinD

```bash
# Start local cluster
make up

# Apply your changes
kubectl apply -f your-changes.yaml

# Run tests
make test

# Cleanup
make down
```

### Policy Testing

```bash
# Test Kyverno policies
kyverno apply policies/kyverno/cluster-policies/ --resource test-resource.yaml
```

## 📄 Architecture Decision Records (ADRs)

For significant architectural changes, create an ADR:

1. Copy `docs/adr/template.md` to `docs/adr/NNN-title.md`
2. Fill in the template
3. Submit as part of your PR

## 🔒 Security

- **Never commit secrets** - Use Vault/External Secrets
- Report security issues privately to maintainers
- Follow the principle of least privilege
- All containers must run as non-root

## 📫 Getting Help

- Open an issue for questions
- Join discussions in GitHub Discussions
- Check existing issues and PRs before creating new ones

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to the Agentic DevSecOps Platform! 🎉
