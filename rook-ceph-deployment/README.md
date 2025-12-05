# Rook-Ceph Deployment

This component deploys [Rook-Ceph](https://rook.io/) to provide S3-compatible object storage on Kubernetes.

## ⚠️ Requirements

- **Resources**: Rook-Ceph is resource-intensive. Ensure your cluster has at least:
  - 3+ CPUs
  - 6GB+ RAM
  - 10GB+ Free Disk Space
- **Environment**: By default, this chart is configured for a "playground" environment (single replica, hostPath storage). **Do not use this default configuration for production.**

## 🚀 Quick Start

```bash
cd rook-ceph-deployment
./install.sh
```

This script will:
1. Install the Rook-Ceph Operator.
2. Deploy a Ceph Cluster.
3. Provision a Ceph Object Store (S3).

## 🔧 Configuration

The `values.yaml` file configures the `rook-ceph-cluster` chart.

Key configurations:
- `cephClusterSpec.mon.count`: 1 (for dev/test)
- `cephClusterSpec.mgr.count`: 1 (for dev/test)
- `cephClusterSpec.storage.useAllNodes`: true
- `cephObjectStores`: Defines the S3 store named `my-store`.

## 🧪 Verification

After installation, verify the pods are running:

```bash
kubectl get pods -n rook-ceph
```

You should see:
- `rook-ceph-operator`
- `rook-ceph-mon-*`
- `rook-ceph-mgr-*`
- `rook-ceph-osd-*`
- `rook-ceph-rgw-my-store-*` (The S3 gateway)

### Access S3

To access the S3 API locally:

```bash
# Port forward the RGW service
kubectl port-forward -n rook-ceph svc/rook-ceph-rgw-my-store 8000:80
```

Then use AWS CLI or MinIO Client:

```bash
aws --endpoint-url http://localhost:8000 s3 ls
```

## 🧹 Uninstall

```bash
./uninstall.sh
```

**Note:** Rook leaves data on the host (`/var/lib/rook`). If you plan to reinstall, you must clean this directory on the node(s).
