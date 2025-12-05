#!/bin/bash

# Start Minikube with Rook-Ceph appropriate settings

set -e

echo "=========================================="
echo "Starting Minikube for Rook-Ceph Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube is not installed.${NC}"
    echo "Please install Minikube: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Configuration variables
# Rook-Ceph requires more resources than standard MinIO
DRIVER="${DRIVER:-docker}"
CPUS="${CPUS:-4}"           # Increased from 2
MEMORY="${MEMORY:-8192}"    # Increased from 4096 (8GB)
DISK_SIZE="${DISK_SIZE:-50g}" # Increased from 20g
KUBERNETES_VERSION="${KUBERNETES_VERSION:-stable}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Driver: $DRIVER"
echo "  CPUs: $CPUS"
echo "  Memory: ${MEMORY}MB"
echo "  Disk Size: $DISK_SIZE"
echo "  Kubernetes Version: $KUBERNETES_VERSION"
echo ""

# Check if minikube is already running or in a broken state
STATUS=$(minikube status --format='{{.Host}}' 2>/dev/null || true)

if [[ "$STATUS" == "Running" ]]; then
    echo -e "${YELLOW}Minikube is already running.${NC}"
    echo ""
    minikube status
    echo ""
    read -p "Do you want to stop and restart with these settings? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping existing Minikube cluster...${NC}"
        minikube stop || true
        echo -e "${YELLOW}Deleting existing Minikube cluster...${NC}"
        minikube delete
    else
        echo -e "${GREEN}Using existing Minikube cluster.${NC}"
        echo -e "${YELLOW}WARNING: Ensure existing cluster has sufficient resources (4CPU, 8GB RAM).${NC}"
        exit 0
    fi
elif [[ -n "$STATUS" && "$STATUS" != "Stopped" && "$STATUS" != *"not found"* ]]; then
    # Handle cases where it's not Running but also not empty (e.g. "Saved", "Error")
    # If it says "not found", it means we can just start
    echo -e "${YELLOW}Minikube status is: $STATUS${NC}"
    echo "It might be in a broken state."
    read -p "Do you want to delete and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        minikube delete
    fi
else
    # If status failed or returned empty, it might be stopped or broken.
    # We'll try to delete if it looks like it exists but is broken
    if minikube profile list 2>/dev/null | grep -q "minikube"; then
        echo -e "${YELLOW}Minikube profile exists but status check failed.${NC}"
        echo "Cleaning up potential broken state..."
        minikube delete || true
    fi
fi

# Start Minikube
echo -e "${YELLOW}Starting Minikube...${NC}"
# We add --extra-disks=1 to simulate a raw device for Rook if needed, 
# though our default values.yaml uses hostPath/PVCs. 
# Adding an extra disk is good practice for Rook testing.
minikube start \
    --driver=$DRIVER \
    --cpus=$CPUS \
    --memory=$MEMORY \
    --disk-size=$DISK_SIZE \
    --kubernetes-version=$KUBERNETES_VERSION \
    --extra-disks=1

echo ""
echo -e "${GREEN}Minikube started successfully!${NC}"
echo ""

# Enable addons
echo -e "${YELLOW}Enabling useful Minikube addons...${NC}"
minikube addons enable metrics-server
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
# Dashboard is often useful for debugging Rook
minikube addons enable dashboard

echo ""
echo -e "${GREEN}=========================================="
echo "Minikube is Ready for Rook-Ceph!"
echo "==========================================${NC}"
echo ""
echo "Cluster Information:"
minikube status
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Install Rook-Ceph: ./install.sh"
echo "  2. Verify deployment: ./verify-rook.sh"
