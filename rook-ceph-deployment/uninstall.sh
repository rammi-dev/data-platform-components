#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}WARNING: This will uninstall Rook-Ceph Cluster and Operator.${NC}"
echo -e "${RED}Data in /var/lib/rook (on host) may persist and prevent clean re-installation.${NC}"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo -e "${YELLOW}Uninstalling Rook-Ceph Cluster...${NC}"
helm uninstall rook-ceph-cluster -n rook-ceph || true

# Wait a bit for resources to clean up, though finalizers might block
echo -e "${YELLOW}Waiting for cleanup...${NC}"
sleep 5

echo -e "${YELLOW}Uninstalling Rook-Ceph Operator...${NC}"
helm uninstall rook-ceph -n rook-ceph || true

echo -e "${YELLOW}Deleting namespace rook-ceph...${NC}"
kubectl delete namespace rook-ceph --ignore-not-found

echo -e "${RED}IMPORTANT: To fully clean up for a fresh install, you may need to run the following on your nodes:${NC}"
echo -e "  sudo rm -rf /var/lib/rook"
echo -e "  # And potentially wipe the disks used by OSDs"
