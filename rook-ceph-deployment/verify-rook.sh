#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Verifying Rook-Ceph Deployment...${NC}"

# Check Operator
echo -n "Checking Rook Operator: "
if kubectl get deployment -n rook-ceph rook-ceph-operator &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED (Operator deployment not found)${NC}"
    exit 1
fi

# Check Cluster
echo -n "Checking Ceph Cluster: "
# We check for the presence of OSD pods as a proxy for cluster health in this simple check
OSD_PODS=$(kubectl get pods -n rook-ceph -l app=rook-ceph-osd --no-headers 2>/dev/null | wc -l)
if [ "$OSD_PODS" -gt 0 ]; then
    echo -e "${GREEN}OK ($OSD_PODS OSDs found)${NC}"
else
    echo -e "${RED}WARNING (No OSD pods found yet - might still be initializing)${NC}"
fi

# Check RGW (Object Store)
echo -n "Checking Object Store (RGW): "
RGW_PODS=$(kubectl get pods -n rook-ceph -l app=rook-ceph-rgw --no-headers 2>/dev/null | wc -l)
if [ "$RGW_PODS" -gt 0 ]; then
    echo -e "${GREEN}OK ($RGW_PODS RGW pods found)${NC}"
else
    echo -e "${RED}WARNING (No RGW pods found yet)${NC}"
fi

echo -e "${GREEN}Verification checks completed.${NC}"
echo "To test S3 access, run:"
echo "  kubectl port-forward -n rook-ceph svc/rook-ceph-rgw-my-store 8000:80"
echo "  aws --endpoint-url http://localhost:8000 s3 ls"
