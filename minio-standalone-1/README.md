# MinIO Standalone Helm Chart

## Project Description

This is a **Helm chart wrapper project** that deploys MinIO object storage using the official MinIO Helm chart as a subchart dependency. The project provides a declarative, production-ready configuration for MinIO with automated provisioning of buckets, users, policies, and service accounts.

### What This Project Does

- **Deploys MinIO**: Uses Bitnami's battle-tested MinIO Helm chart (latest version)
- **Automated Provisioning**: Creates buckets, users, and IAM policies automatically on deployment
- **Default Configuration**: Provides a pre-configured setup suitable for development and testing
- **MinIO Console**: Includes the MinIO web UI for easy management and monitoring
- **Declarative Setup**: All configuration is defined in `values.yaml` for GitOps workflows

### Project Architecture

```
Parent Chart (minio-standalone)
    └── Subchart: minio/minio (official chart)
        ├── MinIO Server (API: port 9000)
        ├── MinIO Console UI (port 9001)
        └── Provisioning Jobs (creates buckets, users, policies)
```

### Use Cases

- **Development Environment**: Quick MinIO setup for local Kubernetes development
- **Data Platform Components**: Object storage layer for data pipelines and applications
- **S3-Compatible Storage**: Drop-in replacement for AWS S3 in on-premises or cloud environments
- **Application Testing**: Test S3 integration without cloud dependencies

### Pre-configured Resources

1. **Bucket**: `minio-temporary` - A bucket for temporary object storage
2. **User**: `default-minio` - An application service account
3. **Policy**: `minio-temporary-policy` - Grants full S3 permissions to the bucket
4. **Access**: The user has complete read/write/delete access to the bucket

This Helm chart deploys MinIO using the official MinIO chart as a subchart, with pre-configured bucket, user, service account, and policy.

## Features

- **MinIO Server**: Latest version via Bitnami chart
- **MinIO Console UI**: Web interface for MinIO management
- **Pre-configured Bucket**: `minio-temporary`
- **User Account**: `default-minio` with full access to `minio-temporary` bucket
- **Policy**: `minio-temporary-policy` granting full S3 permissions to the bucket
- **Service Account**: Automatically created for the user

## Prerequisites

- Kubernetes cluster 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)

## Installation

### 1. Add MinIO Repository and Update Dependencies

```bash
helm repo add minio https://charts.min.io/
helm repo update
helm dependency update
```

### 2. Install the Chart

```bash
# Install with default values
helm install minio-standalone .

# Install with custom namespace
helm install minio-standalone . --namespace minio --create-namespace

# Install with custom values
helm install minio-standalone . -f custom-values.yaml
```

### 3. Verify Installation

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=minio

# Check services
kubectl get svc -l app.kubernetes.io/name=minio
```

## Access MinIO

### Access MinIO API

```bash
# Port forward to access MinIO API
kubectl port-forward svc/minio-standalone-minio 9000:9000

# MinIO endpoint will be available at: http://localhost:9000
```

### Access MinIO Console (UI)

```bash
# Port forward to access MinIO Console
kubectl port-forward svc/minio-standalone-minio 9001:9001

# MinIO Console will be available at: http://localhost:9001
```

### Login Credentials

**Root User:**
- Username: `admin`
- Password: `adminpassword123`

**Application User:**
- Username: `default-minio`
- Password: `defaultminio123`
- Access: Full permissions on `minio-temporary` bucket

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.auth.rootUser` | MinIO root username | `admin` |
| `minio.auth.rootPassword` | MinIO root password | `adminpassword123` |
| `minio.defaultBuckets` | Default buckets to create | `minio-temporary` |
| `minio.provisioning.enabled` | Enable provisioning | `true` |
| `minio.service.type` | Service type | `ClusterIP` |
| `minio.persistence.enabled` | Enable persistence | `true` |
| `minio.persistence.size` | Storage size | `10Gi` |

### Customizing Values

Create a `custom-values.yaml` file:

```yaml
minio:
  auth:
    rootUser: myadmin
    rootPassword: mysecurepassword
  
  persistence:
    size: 50Gi
  
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
```

Install with custom values:

```bash
helm install minio-standalone . -f custom-values.yaml
```

## Bucket and Policy Configuration

The chart automatically creates:

1. **Bucket**: `minio-temporary`
2. **Policy**: `minio-temporary-policy` with full S3 permissions
3. **User**: `default-minio` with the policy attached

### Policy Details

The `minio-temporary-policy` grants:
- Full access to the `minio-temporary` bucket
- All S3 operations (s3:*)
- Access to bucket and all objects within

## Uninstallation

```bash
helm uninstall minio-standalone

# If installed in a custom namespace
helm uninstall minio-standalone --namespace minio
```

## Upgrading

```bash
# Update dependencies
helm dependency update

# Upgrade the release
helm upgrade minio-standalone .
```

## Troubleshooting

### Check Pod Logs

```bash
kubectl logs -l app.kubernetes.io/name=minio
```

### Check Provisioning Jobs

```bash
kubectl get jobs
kubectl logs job/minio-standalone-minio-provisioning
```

### Verify Bucket and User Creation

1. Access MinIO Console (port-forward to 9001)
2. Login with root credentials
3. Navigate to Buckets and Users sections to verify

## Notes

- Change default passwords in production environments
- Configure ingress for external access if needed
- Adjust resource limits based on your workload
- Enable TLS for production deployments
- Consider backup strategies for persistent data

## References

- [Official MinIO Helm Chart](https://github.com/minio/minio/tree/master/helm/minio)
- [MinIO Documentation](https://min.io/docs/minio/kubernetes/upstream/)
- [MinIO GitHub Repository](https://github.com/minio/minio)

## License

This chart is provided as-is for use with the official MinIO Helm chart.
