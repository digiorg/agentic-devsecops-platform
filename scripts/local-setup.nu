#!/usr/bin/env nu

# =============================================================================
# Local Development Environment Setup
# =============================================================================
# This script manages the local KinD cluster for development.
#
# Usage:
#   nu scripts/local-setup.nu up       # Start local cluster
#   nu scripts/local-setup.nu down     # Destroy local cluster
#   nu scripts/local-setup.nu reset    # Reset cluster
#   nu scripts/local-setup.nu status   # Show cluster status
# =============================================================================

# Configuration
let CLUSTER_NAME = "agentic-dev"
let KIND_CONFIG = "platform/bootstrap/kind-config.yaml"
let KUBECONFIG_PATH = $"($env.PWD)/kubeconfig-local.yaml"

# Main entry point
def main [] {
    print "Agentic DevSecOps Platform - Local Development"
    print ""
    print "Commands:"
    print "  up      - Create local cluster and install components"
    print "  down    - Destroy local cluster"
    print "  reset   - Reset cluster (down + up)"
    print "  status  - Show cluster status"
    print "  install - Install platform components on existing cluster"
    print ""
    print $"Usage: nu scripts/local-setup.nu <command>"
}

# Create local cluster and install all components
def "main up" [
    --skip-components  # Skip installing platform components
] {
    print $"(ansi green_bold)Creating local development cluster...(ansi reset)"
    
    # Check prerequisites
    check_prerequisites
    
    # Create cluster if it doesn't exist
    if (cluster_exists) {
        print $"(ansi yellow)Cluster '($CLUSTER_NAME)' already exists.(ansi reset)"
    } else {
        print $"Creating KinD cluster '($CLUSTER_NAME)'..."
        kind create cluster --config $KIND_CONFIG --kubeconfig $KUBECONFIG_PATH
    }
    
    # Set KUBECONFIG
    $env.KUBECONFIG = $KUBECONFIG_PATH
    
    # Wait for cluster to be ready
    print "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s
    
    if not $skip_components {
        # Install platform components
        main install
    }
    
    print ""
    print $"(ansi green_bold)✓ Local cluster is ready!(ansi reset)"
    print ""
    print $"Export kubeconfig:"
    print $"  export KUBECONFIG=($KUBECONFIG_PATH)"
    print ""
    print "Access services:"
    print "  ArgoCD:     https://localhost:30080 (admin / see password below)"
    print "  Grafana:    http://localhost:30090"
    print ""
    
    # Print ArgoCD password if available
    try {
        let password = (kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | decode base64)
        print $"ArgoCD admin password: ($password)"
    } catch {
        print "(ArgoCD not yet installed or password not available)"
    }
}

# Destroy local cluster
def "main down" [] {
    print $"(ansi yellow_bold)Destroying local cluster...(ansi reset)"
    
    if (cluster_exists) {
        kind delete cluster --name $CLUSTER_NAME
        rm -f $KUBECONFIG_PATH
        print $"(ansi green)✓ Cluster destroyed.(ansi reset)"
    } else {
        print $"Cluster '($CLUSTER_NAME)' does not exist."
    }
}

# Reset cluster (destroy + create)
def "main reset" [] {
    print $"(ansi yellow_bold)Resetting local cluster...(ansi reset)"
    main down
    main up
}

# Show cluster status
def "main status" [] {
    print $"(ansi cyan_bold)Cluster Status(ansi reset)"
    print "=============="
    
    if (cluster_exists) {
        print $"(ansi green)● Cluster '($CLUSTER_NAME)' is running(ansi reset)"
        print ""
        
        $env.KUBECONFIG = $KUBECONFIG_PATH
        
        print "Nodes:"
        kubectl get nodes -o wide
        
        print ""
        print "Platform Components:"
        
        # Check namespaces
        let namespaces = ["argocd", "crossplane-system", "vault", "kyverno", "monitoring"]
        for ns in $namespaces {
            let status = try {
                let pods = (kubectl get pods -n $ns --no-headers 2>/dev/null | lines | length)
                if $pods > 0 {
                    $"(ansi green)● ($ns) - ($pods) pods(ansi reset)"
                } else {
                    $"(ansi yellow)○ ($ns) - no pods(ansi reset)"
                }
            } catch {
                $"(ansi red)✗ ($ns) - not installed(ansi reset)"
            }
            print $"  ($status)"
        }
    } else {
        print $"(ansi red)✗ Cluster '($CLUSTER_NAME)' is not running(ansi reset)"
        print ""
        print "Run 'nu scripts/local-setup.nu up' to create the cluster."
    }
}

# Install platform components
def "main install" [
    --components: string = "all"  # Components to install (all, argocd, ingress, crossplane, vault, kyverno, monitoring)
] {
    print $"(ansi cyan_bold)Installing platform components...(ansi reset)"
    
    $env.KUBECONFIG = $KUBECONFIG_PATH
    
    let install_all = $components == "all"
    
    # 1. Install Ingress Controller (NGINX)
    if $install_all or ($components | str contains "ingress") {
        install_ingress
    }
    
    # 2. Install ArgoCD
    if $install_all or ($components | str contains "argocd") {
        install_argocd
    }
    
    # 3. Install Crossplane
    if $install_all or ($components | str contains "crossplane") {
        install_crossplane
    }
    
    # 4. Install Vault (dev mode)
    if $install_all or ($components | str contains "vault") {
        install_vault
    }
    
    # 5. Install Kyverno
    if $install_all or ($components | str contains "kyverno") {
        install_kyverno
    }
    
    # 6. Install Monitoring (optional, can be slow)
    if $components | str contains "monitoring" {
        install_monitoring
    }
    
    print ""
    print $"(ansi green_bold)✓ Platform components installed!(ansi reset)"
}

# -----------------------------------------------------------------------------
# Component Installation Functions
# -----------------------------------------------------------------------------

def install_ingress [] {
    print "Installing NGINX Ingress Controller..."
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    print "Waiting for ingress controller..."
    sleep 10sec
    
    try {
        kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s
    } catch {
        print $"(ansi yellow)Warning: Ingress controller not ready yet, continuing...(ansi reset)"
    }
}

def install_argocd [] {
    print "Installing ArgoCD..."
    
    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Helm repo
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Install ArgoCD
    helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace --set 'server.service.type=NodePort' --set 'server.service.nodePortHttp=30080' --set 'server.service.nodePortHttps=30443' --set 'configs.params.server\.insecure=true' --wait --timeout 5m
    
    print $"(ansi green)✓ ArgoCD installed(ansi reset)"
}

def install_crossplane [] {
    print "Installing Crossplane..."
    
    # Add Helm repo
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    
    # Install Crossplane
    helm upgrade --install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace --wait --timeout 5m
    
    print $"(ansi green)✓ Crossplane installed(ansi reset)"
}

def install_vault [] {
    print "Installing Vault (dev mode)..."
    
    # Add Helm repo
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update
    
    # Install Vault in dev mode
    helm upgrade --install vault hashicorp/vault --namespace vault --create-namespace --set 'server.dev.enabled=true' --set 'server.dev.devRootToken=root' --set 'ui.enabled=true' --wait --timeout 5m
    
    print $"(ansi green)✓ Vault installed (dev mode, root token: 'root')(ansi reset)"
}

def install_kyverno [] {
    print "Installing Kyverno..."
    
    # Add Helm repo
    helm repo add kyverno https://kyverno.github.io/kyverno/
    helm repo update
    
    # Install Kyverno
    helm upgrade --install kyverno kyverno/kyverno --namespace kyverno --create-namespace --set 'replicaCount=1' --wait --timeout 5m
    
    print $"(ansi green)✓ Kyverno installed(ansi reset)"
}

def install_monitoring [] {
    print "Installing Prometheus Stack (this may take a while)..."
    
    # Add Helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install with minimal config for local dev
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set 'grafana.service.type=NodePort' --set 'grafana.service.nodePort=30090' --set 'prometheus.prometheusSpec.retention=1d' --set 'alertmanager.enabled=false' --wait --timeout 10m
    
    print $"(ansi green)✓ Monitoring installed(ansi reset)"
}

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

def check_prerequisites [] {
    print "Checking prerequisites..."
    
    let tools = [
        ["kind", "https://kind.sigs.k8s.io/docs/user/quick-start/#installation"],
        ["kubectl", "https://kubernetes.io/docs/tasks/tools/"],
        ["helm", "https://helm.sh/docs/intro/install/"]
    ]
    
    mut missing = []
    
    for tool in $tools {
        let name = $tool.0
        let url = $tool.1
        
        let exists = (which $name | length) > 0
        if not $exists {
            $missing = ($missing | append $name)
            print $"(ansi red)✗ ($name) not found(ansi reset) - Install: ($url)"
        } else {
            print $"(ansi green)✓ ($name)(ansi reset)"
        }
    }
    
    if ($missing | length) > 0 {
        print ""
        print $"(ansi red_bold)Missing required tools. Please install them and try again.(ansi reset)"
        exit 1
    }
    
    print ""
}

def cluster_exists [] -> bool {
    let clusters = (kind get clusters 2>/dev/null | lines)
    $CLUSTER_NAME in $clusters
}
