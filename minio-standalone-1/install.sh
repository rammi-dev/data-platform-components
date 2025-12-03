#!/bin/bash

# MinIO Standalone Installation Script

set -e

echo "=========================================="
echo "MinIO Standalone Helm Chart Installation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: Helm is not installed. Please install Helm first.${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Add MinIO repository
echo -e "${YELLOW}Adding MinIO Helm repository...${NC}"
helm repo add minio https://charts.min.io/ 2>/dev/null || echo "MinIO repo already exists"
helm repo update

# Update dependencies
echo -e "${YELLOW}Updating chart dependencies...${NC}"
helm dependency update

# Install or upgrade
RELEASE_NAME="minio-standalone"
NAMESPACE="${1:-minio-standalone}"

echo -e "${YELLOW}Creating namespace: $NAMESPACE${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo -e "${YELLOW}Installing MinIO Standalone chart...${NC}"
helm upgrade --install $RELEASE_NAME . \
    --namespace $NAMESPACE \
    --wait \
    --timeout 5m

echo ""
echo -e "${GREEN}=========================================="
echo "Installation Complete!"
echo "==========================================${NC}"
echo ""
echo "To access MinIO API:"
echo "  kubectl port-forward --namespace $NAMESPACE svc/$RELEASE_NAME-minio 9000:9000"
echo "  API endpoint: http://localhost:9000"
echo ""
echo "To access MinIO Console (UI):"
echo "  kubectl port-forward --namespace $NAMESPACE svc/$RELEASE_NAME-minio 9001:9001"
echo "  Console: http://localhost:9001"
echo ""
echo "Default credentials:"
echo "  Root - Username: admin, Password: adminpassword123"
echo "  User - Username: default-minio, Password: defaultminio123"
echo ""
echo "Pre-configured bucket: minio-temporary"
echo ""
