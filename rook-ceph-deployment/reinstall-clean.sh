#!/bin/bash
set -e

echo "=== Starting Clean Re-install of Rook-Ceph on Minikube ==="

# 1. Delete and Purge Minikube
echo "--- Step 1: Deleting Minikube ---"
minikube delete --all --purge

# 2. Start Minikube with optimized settings
echo "--- Step 2: Starting Minikube ---"
./start-minikube.sh

# 3. Install Rook-Ceph
echo "--- Step 3: Installing Rook-Ceph ---"
./install.sh

echo "=== Re-install Complete. Waiting for OSDs to come up... ==="
kubectl get pods -n rook-ceph -w
