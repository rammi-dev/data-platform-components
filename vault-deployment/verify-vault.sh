#!/bin/bash

set -e

echo "=========================================="
echo "Vault Deployment Verification"
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

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Vault pod is running
print_info "Checking Vault pod status..."
VAULT_POD=$(kubectl get pods -l app.kubernetes.io/name=vault -l component=server -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$VAULT_POD" ]; then
    print_error "Vault pod not found!"
    exit 1
fi

POD_STATUS=$(kubectl get pod "$VAULT_POD" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    print_error "Vault pod is not running. Status: $POD_STATUS"
    exit 1
fi

print_success "Vault pod is running: $VAULT_POD"
echo ""

# Check Vault status
print_info "Checking Vault status..."
kubectl exec -it -n "$NAMESPACE" "$VAULT_POD" -- vault status
echo ""

# List secrets
print_info "Listing MinIO secrets in Vault..."
echo ""
kubectl exec -it -n "$NAMESPACE" "$VAULT_POD" -- vault kv list secret/minio
echo ""

# Retrieve MinIO root credentials
print_info "Retrieving MinIO root credentials..."
echo ""
kubectl exec -it -n "$NAMESPACE" "$VAULT_POD" -- vault kv get secret/minio/root
echo ""

# Retrieve MinIO user credentials
print_info "Retrieving MinIO user credentials..."
echo ""
kubectl exec -it -n "$NAMESPACE" "$VAULT_POD" -- vault kv get secret/minio/users/default-minio
echo ""

# Display policy
print_info "Displaying MinIO policy..."
echo ""
kubectl exec -it -n "$NAMESPACE" "$VAULT_POD" -- vault policy read minio-policy
echo ""

print_success "Vault verification complete!"
echo ""
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""
echo "To access Vault UI locally:"
echo "  kubectl port-forward -n $NAMESPACE $VAULT_POD 8200:8200"
echo "  Then open: http://localhost:8200"
echo "  Token: root"
echo ""
echo "To execute Vault commands:"
echo "  kubectl exec -it -n $NAMESPACE $VAULT_POD -- vault <command>"
echo ""
