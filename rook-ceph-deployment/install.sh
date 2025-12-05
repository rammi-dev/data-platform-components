#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Rook-Ceph Deployment...${NC}"

# 1. Add Rook Helm Repo
echo -e "${YELLOW}Adding Rook Helm repository...${NC}"
helm repo add rook-release https://charts.rook.io/release
helm repo update

# 2. Install Rook Operator
echo -e "${YELLOW}Installing Rook-Ceph Operator...${NC}"
# We install the operator separately because it's a cluster-wide resource usually
# and often managed independently of the specific cluster instance.
helm upgrade --install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph \
  --version v1.12.8

echo -e "${YELLOW}Waiting for Rook-Ceph Operator to be ready...${NC}"
kubectl rollout status deployment/rook-ceph-operator -n rook-ceph --timeout=120s

# 3. Install Rook Cluster (via our wrapper chart)
echo -e "${YELLOW}Installing Rook-Ceph Cluster and Object Store...${NC}"
helm dependency update .
helm upgrade --install rook-ceph-cluster . --namespace rook-ceph

echo -e "${GREEN}Deployment initiated!${NC}"
echo -e "It may take a few minutes for the OSDs and Object Store to be fully ready."
echo -e "Check status with: ${YELLOW}kubectl get pods -n rook-ceph${NC}"
