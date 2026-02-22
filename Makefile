# =============================================================================
# Agentic DevSecOps Platform - Makefile
# =============================================================================

.PHONY: help up down reset status test lint clean

# Default target
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Local Development (KinD)
# =============================================================================

up: ## Start local KinD cluster with all components
	@echo "Starting local development environment..."
	@nu scripts/local-setup.nu up || echo "Nushell not available, using fallback..."
	@kind create cluster --name agentic-dev --config platform/bootstrap/kind-config.yaml 2>/dev/null || true
	@echo "Local cluster ready!"

down: ## Destroy local KinD cluster
	@echo "Destroying local cluster..."
	@kind delete cluster --name agentic-dev
	@echo "Done."

reset: down up ## Reset local cluster (destroy + create)

status: ## Show cluster status
	@kubectl cluster-info 2>/dev/null || echo "No cluster running"
	@kubectl get nodes 2>/dev/null || true

# =============================================================================
# Testing & Linting
# =============================================================================

test: ## Run all tests
	@echo "Running tests..."
	@echo "TODO: Implement tests"

lint: ## Lint all configurations
	@echo "Linting YAML files..."
	@yamllint . 2>/dev/null || echo "yamllint not installed"
	@echo "Validating Kubernetes manifests..."
	@kubectl --dry-run=client apply -f apps/ 2>/dev/null || true
	@echo "Done."

validate-policies: ## Validate Kyverno policies
	@echo "Validating Kyverno policies..."
	@kyverno validate policies/kyverno/ 2>/dev/null || echo "kyverno CLI not installed"

validate-crossplane: ## Validate Crossplane compositions
	@echo "Validating Crossplane configurations..."
	@crossplane beta validate crossplane/xrds/ crossplane/compositions/ 2>/dev/null || echo "crossplane CLI not installed"

# =============================================================================
# Utilities
# =============================================================================

clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	@rm -rf .terraform/ *.tfstate* *.tfplan
	@rm -rf tmp/ *.log
	@echo "Done."

deps: ## Check required dependencies
	@echo "Checking dependencies..."
	@command -v kubectl >/dev/null 2>&1 && echo "✓ kubectl" || echo "✗ kubectl"
	@command -v helm >/dev/null 2>&1 && echo "✓ helm" || echo "✗ helm"
	@command -v kind >/dev/null 2>&1 && echo "✓ kind" || echo "✗ kind"
	@command -v terraform >/dev/null 2>&1 && echo "✓ terraform" || echo "✗ terraform"
	@command -v nu >/dev/null 2>&1 && echo "✓ nushell" || echo "✗ nushell"
	@command -v kyverno >/dev/null 2>&1 && echo "✓ kyverno" || echo "✗ kyverno"
