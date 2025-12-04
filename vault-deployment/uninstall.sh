#!/bin/bash

set -e

echo "=========================================="
echo "HashiCorp Vault Deployment Uninstallation"
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Uninstall Helm release
print_info "Uninstalling Vault Helm release..."
helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" || print_warning "Release not found or already uninstalled"

echo ""

# Clean up any remaining resources
print_info "Cleaning up remaining resources..."

# Delete init job if it exists
kubectl delete job -l app.kubernetes.io/component=vault-init --namespace "$NAMESPACE" --ignore-not-found=true

# Delete service account
kubectl delete serviceaccount "${RELEASE_NAME}-init" --namespace "$NAMESPACE" --ignore-not-found=true

echo ""
print_info "Uninstallation complete!"
echo ""
