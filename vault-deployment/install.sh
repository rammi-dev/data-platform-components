#!/bin/bash

set -e

echo "=========================================="
echo "HashiCorp Vault Deployment Installation"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RELEASE_NAME="vault-deployment"
NAMESPACE="default"
CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_info "Checking prerequisites..."

if ! command_exists helm; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

if ! command_exists kubectl; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

print_info "All prerequisites satisfied!"
echo ""

# Add HashiCorp Helm repository
print_info "Adding HashiCorp Helm repository..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo ""

# Update Helm dependencies
print_info "Updating Helm chart dependencies..."
cd "$CHART_DIR"
helm dependency update

echo ""

# Install Vault
print_info "Installing Vault using Helm..."
helm upgrade --install "$RELEASE_NAME" . \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout 5m

echo ""

# Wait for Vault pod to be ready
print_info "Waiting for Vault pod to be ready..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=vault \
    -l component=server \
    --namespace "$NAMESPACE" \
    --timeout=300s

echo ""

# Wait for init job to complete
print_info "Waiting for Vault initialization job to complete..."
kubectl wait --for=condition=complete job \
    -l app.kubernetes.io/component=vault-init \
    --namespace "$NAMESPACE" \
    --timeout=300s || {
    print_warning "Init job did not complete successfully. Checking logs..."
    kubectl logs -l app.kubernetes.io/component=vault-init --namespace "$NAMESPACE" --tail=50
}

echo ""

# Get Vault pod name
VAULT_POD=$(kubectl get pods -l app.kubernetes.io/name=vault -l component=server -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')

print_info "Vault deployment completed successfully!"
echo ""
echo "=========================================="
echo "Vault Access Information"
echo "=========================================="
echo ""
echo "Vault Pod: $VAULT_POD"
echo "Namespace: $NAMESPACE"
echo "Vault Address (in-cluster): http://${RELEASE_NAME}-vault:8200"
echo "Root Token: root"
echo ""
echo "To access Vault UI locally, run:"
echo "  kubectl port-forward -n $NAMESPACE $VAULT_POD 8200:8200"
echo "  Then open: http://localhost:8200"
echo ""
echo "To access Vault CLI:"
echo "  kubectl exec -it -n $NAMESPACE $VAULT_POD -- vault status"
echo ""
echo "To retrieve MinIO credentials from Vault:"
echo "  kubectl exec -it -n $NAMESPACE $VAULT_POD -- vault kv get secret/minio/root"
echo ""
echo "=========================================="
echo ""

# Display stored secrets
print_info "Verifying stored secrets..."
echo ""
kubectl exec -it -n "$NAMESPACE" "$VAULT_POD" -- vault kv list secret/minio || true

echo ""
print_info "Installation complete! Run ./verify-vault.sh to verify the deployment."
