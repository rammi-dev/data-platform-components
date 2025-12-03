#!/bin/bash

# MinIO Standalone Uninstallation Script

set -e

echo "============================================"
echo "MinIO Standalone Helm Chart Uninstallation"
echo "============================================"
echo ""

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

RELEASE_NAME="minio-standalone"
NAMESPACE="${1:-minio-standalone}"

echo -e "${YELLOW}Uninstalling MinIO Standalone from namespace: $NAMESPACE${NC}"
helm uninstall $RELEASE_NAME --namespace $NAMESPACE

echo ""
echo -e "${RED}⚠️  Note: PersistentVolumeClaims are not automatically deleted.${NC}"
echo ""
echo "To delete PVCs (this will delete all data):"
echo "  kubectl delete pvc -l app.kubernetes.io/name=minio --namespace $NAMESPACE"
echo ""
echo -e "${GREEN}Uninstallation complete!${NC}"
