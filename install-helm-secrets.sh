#!/bin/bash

set -e

echo "=========================================="
echo "Installing helm-secrets Plugin"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

print_info "Helm version:"
helm version --short 2>/dev/null || helm version
echo ""

# Clean up any corrupted installation
PLUGIN_DIR="$HOME/.local/share/helm/plugins/helm-secrets"
if [ -d "$PLUGIN_DIR" ]; then
    # Check if plugin is corrupted
    if helm plugin list 2>&1 | grep -q "both platformCommand and command are set"; then
        print_warning "Found corrupted helm-secrets installation, cleaning up..."
        rm -rf "$PLUGIN_DIR"
        print_success "Cleaned up corrupted installation!"
        echo ""
    fi
fi

# Check if helm-secrets is already installed (and working)
if helm plugin list 2>/dev/null | grep -q "secrets"; then
    print_warning "helm-secrets plugin is already installed!"
    echo ""
    helm plugin list | grep secrets
    echo ""
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstalling existing helm-secrets plugin..."
        rm -rf "$PLUGIN_DIR"
    else
        print_info "Keeping existing installation."
        exit 0
    fi
fi

# Install helm-secrets plugin
print_info "Installing helm-secrets plugin (latest version)..."
helm plugin install https://github.com/jkroepke/helm-secrets --verify=false 2>&1 | grep -v "both platformCommand and command are set" || true

echo ""

# Fix the platformCommand/command conflict immediately after installation
PLUGIN_DIR="$HOME/.local/share/helm/plugins/helm-secrets"
if [ -f "$PLUGIN_DIR/plugin.yaml" ]; then
    print_info "Fixing plugin.yaml for Helm v4 compatibility..."
    
    # Helm v4 doesn't allow both 'command' and 'platformCommand'
    # We need to use only platformCommand with entries for all platforms
    cat > "$PLUGIN_DIR/plugin.yaml" << 'PLUGIN_EOF'
name: "secrets"
version: "4.6.2"
usage: "Secrets encryption in Helm for Git storing"
description: |-
  This plugin provides secrets values encryption for Helm charts secure storing
useTunnel: false
platformCommand:
  - os: linux
    command: "$HELM_PLUGIN_DIR/scripts/run.sh"
  - os: darwin
    command: "$HELM_PLUGIN_DIR/scripts/run.sh"
  - os: windows
    command: "cmd /c $HELM_PLUGIN_DIR\\scripts\\wrapper\\run.cmd"

downloaders:
  - command: "scripts/run.sh downloader"
    protocols:
      - "secrets"
      - "secrets+gpg-import"
      - "secrets+gpg-import-kubernetes"
      - "secrets+age-import"
      - "secrets+age-import-kubernetes"
      - "secrets+literal"
PLUGIN_EOF
    
    print_success "Fixed plugin configuration for Helm v4!"
    echo ""
fi

# Verify installation
if helm plugin list 2>/dev/null | grep -q "secrets"; then
    print_success "helm-secrets plugin installed successfully!"
    echo ""
    print_info "Installed plugin details:"
    helm plugin list | grep secrets
    echo ""
    print_info "Plugin version:"
    helm secrets --version 2>/dev/null || echo "  (version command not available)"
    echo ""
    print_info "To use helm-secrets with Vault backend, set these environment variables:"
    echo "  export VAULT_ADDR=http://vault-deployment-vault:8200"
    echo "  export VAULT_TOKEN=root"
    echo ""
    print_info "Example usage:"
    echo "  helm secrets upgrade --install minio ./minio-chart -f secrets.yaml"
else
    print_error "Failed to install helm-secrets plugin!"
    exit 1
fi

echo ""
print_success "Installation complete!"
