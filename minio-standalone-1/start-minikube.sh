#!/bin/bash

# Start Minikube with MinIO-appropriate settings

set -e

echo "=========================================="
echo "Starting Minikube for MinIO Deployment"
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
DRIVER="${DRIVER:-docker}"
CPUS="${CPUS:-2}"
MEMORY="${MEMORY:-4096}"
DISK_SIZE="${DISK_SIZE:-20g}"
KUBERNETES_VERSION="${KUBERNETES_VERSION:-stable}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Driver: $DRIVER"
echo "  CPUs: $CPUS"
echo "  Memory: ${MEMORY}MB"
echo "  Disk Size: $DISK_SIZE"
echo "  Kubernetes Version: $KUBERNETES_VERSION"
echo ""

# Check if minikube is already running
if minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube is already running.${NC}"
    echo ""
    minikube status
    echo ""
    read -p "Do you want to stop and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping existing Minikube cluster...${NC}"
        minikube stop
        echo -e "${YELLOW}Deleting existing Minikube cluster...${NC}"
        minikube delete
    else
        echo -e "${GREEN}Using existing Minikube cluster.${NC}"
        echo ""
        echo "To access the cluster:"
        echo "  kubectl get nodes"
        echo "  kubectl get pods -A"
        exit 0
    fi
fi

# Start Minikube
echo -e "${YELLOW}Starting Minikube...${NC}"
minikube start \
    --driver=$DRIVER \
    --cpus=$CPUS \
    --memory=$MEMORY \
    --disk-size=$DISK_SIZE \
    --kubernetes-version=$KUBERNETES_VERSION

echo ""
echo -e "${GREEN}Minikube started successfully!${NC}"
echo ""

# Enable addons that are useful for MinIO
echo -e "${YELLOW}Enabling useful Minikube addons...${NC}"
minikube addons enable metrics-server
minikube addons enable storage-provisioner
minikube addons enable default-storageclass

echo ""
echo -e "${GREEN}=========================================="
echo "Minikube is Ready!"
echo "==========================================${NC}"
echo ""
echo "Cluster Information:"
minikube status
echo ""
echo "Kubernetes Version:"
kubectl version --short
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Install MinIO: ./install.sh"
echo "  2. Check deployment: kubectl get pods"
echo "  3. Access MinIO Console: kubectl port-forward svc/minio-standalone-minio 9001:9001"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  minikube dashboard    - Open Kubernetes dashboard"
echo "  minikube tunnel       - Expose LoadBalancer services"
echo "  minikube stop         - Stop the cluster"
echo "  minikube delete       - Delete the cluster"
echo ""
