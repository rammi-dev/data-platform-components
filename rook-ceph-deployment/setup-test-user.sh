#!/bin/bash
set -e

# Get the tools pod name
TOOLS_POD=$(kubectl get pods -n rook-ceph -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')
echo "Using tools pod: $TOOLS_POD"

# Create user with specific credentials and user-level quota (1GB)
echo "Creating user test-user..."
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin user create \
  --uid=test-user \
  --display-name="Test User" \
  --access-key=test-user \
  --secret-key=test-password \
  --max-size=1073741824

# Enable user quota
echo "Enabling user quota..."
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin quota enable --quota-scope=user --uid=test-user

# Create bucket owned by test-user
echo "Creating bucket test-bucket..."
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin bucket create --bucket=test-bucket --uid=test-user

# Set bucket-level quota (1GB) just in case
echo "Setting bucket quota..."
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin quota set \
  --quota-scope=bucket \
  --uid=test-user \
  --bucket=test-bucket \
  --max-size=1073741824

echo "Enabling bucket quota..."
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin quota enable --quota-scope=bucket --uid=test-user --bucket=test-bucket

echo "Verification:"
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin user info --uid=test-user
kubectl exec -n rook-ceph $TOOLS_POD -- radosgw-admin bucket stats --bucket=test-bucket
