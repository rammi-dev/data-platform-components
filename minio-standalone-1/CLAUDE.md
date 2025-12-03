# MinIO Standalone Helm Chart - Project Description

## Project Overview

This is a **wrapper Helm chart** that deploys MinIO object storage on Kubernetes using the official MinIO Helm chart as a subchart dependency. It provides a simplified, pre-configured setup for deploying MinIO with automated provisioning of buckets, users, and IAM policies.

## What is MinIO?

MinIO is a high-performance, S3-compatible object storage system. It's open-source and can be deployed on-premises or in the cloud as an alternative to AWS S3.

## Project Purpose

This Helm chart wrapper serves as a **declarative configuration layer** on top of the official MinIO chart, providing:

1. **Pre-configured Resources**: Automatically creates buckets, users, and policies on deployment
2. **Simplified Setup**: Ready-to-use configuration for common use cases
3. **GitOps Ready**: All configuration defined in `values.yaml` for version control
4. **Development/Testing**: Quick MinIO setup for local Kubernetes environments (Minikube)
5. **Data Platform Component**: Object storage layer for data pipelines and applications

## Architecture

```
minio-standalone (parent chart)
    │
    └── minio (subchart from https://charts.min.io/)
        ├── MinIO Server Deployment
        │   └── Image: minio/minio:RELEASE.2025-09-07T16-13-09Z
        │
        ├── MinIO Console Service (Web UI on port 9001)
        │
        ├── MinIO API Service (S3-compatible API on port 9000)
        │
        └── Provisioning Jobs (using mc - MinIO Client)
            ├── Creates buckets
            ├── Creates IAM users
            └── Creates IAM policies
```

## Key Components

### 1. MinIO Server
- **Image Source**: Docker Hub (`minio/minio`)
- **Deployment Mode**: Standalone (single instance)
- **Storage**: Persistent volume (10Gi by default)
- **Ports**: 
  - 9000: S3-compatible API
  - 9001: MinIO Console (Web UI)

### 2. MinIO Console
- Web-based UI for managing MinIO
- Accessible at port 9001
- Provides bucket management, user management, monitoring

### 3. MinIO Client (mc)
- Built into MinIO image
- Used by Helm chart post-install hooks
- Provisions buckets, users, and policies automatically

## Default Configuration

### Pre-configured Resources

1. **Bucket**: `minio-temporary`
   - Purpose: Temporary object storage
   - Access: Controlled by IAM policy

2. **User**: `default-minio`
   - Access Key: `default-minio`
   - Secret Key: `defaultminio123`
   - Purpose: Application service account

3. **Policy**: `minio-temporary-policy`
   - Grants: Full S3 permissions (`s3:*`)
   - Scope: `minio-temporary` bucket only
   - Attached to: `default-minio` user

4. **Root User**: `admin`
   - Password: `adminpassword123`
   - Access: Full administrative access

### Resource Limits
- CPU Request: 250m
- CPU Limit: 1000m
- Memory Request: 512Mi
- Memory Limit: 2Gi

## Use Cases

1. **Local Development**: S3-compatible storage for testing applications locally
2. **CI/CD Pipelines**: Object storage for build artifacts and test data
3. **Data Platform**: Storage layer for data engineering workflows
4. **Microservices**: Shared object storage for containerized applications
5. **Backup Storage**: On-premises backup destination

## Technology Stack

- **Container Orchestration**: Kubernetes
- **Package Manager**: Helm 3.x
- **Storage Backend**: MinIO (S3-compatible)
- **Container Registry**: Docker Hub
- **Image**: Official MinIO images

## Dependencies

- Kubernetes cluster (1.19+)
- Helm 3.2.0+
- Storage provisioner (for PersistentVolume)
- MinIO Helm repository: https://charts.min.io/

## File Structure

```
minio-standalone-1/
├── Chart.yaml              # Helm chart metadata and subchart dependency
├── values.yaml            # Configuration values (buckets, users, policies)
├── README.md              # User documentation
├── PROJECT_DESCRIPTION.md # This file - project overview for AI agents
├── .helmignore           # Patterns to ignore in Helm packaging
├── .gitignore            # Git ignore patterns
├── install.sh            # Installation script
├── uninstall.sh          # Uninstallation script
├── start-minikube.sh     # Minikube setup script
├── templates/
│   ├── NOTES.txt         # Post-installation notes
│   └── _helpers.tpl      # Helm template helpers
└── charts/
    └── minio-*.tgz       # Downloaded subchart (after dependency update)
```

## Deployment Flow

1. **Helm Dependency Update**: Downloads MinIO subchart from https://charts.min.io/
2. **Chart Installation**: Deploys MinIO with custom values
3. **MinIO Startup**: Server starts and mounts persistent storage
4. **Provisioning Jobs**: Post-install hooks run `mc` commands to:
   - Create `minio-temporary` bucket
   - Create `minio-temporary-policy` IAM policy
   - Create `default-minio` user with the policy attached
5. **Service Ready**: MinIO API and Console become accessible

## Configuration Management

All configuration is centralized in `values.yaml` under the `minio:` key:

- **Image settings**: Container image and tag
- **Authentication**: Root and user credentials
- **Storage**: Persistence, size, storage class
- **Resources**: CPU/Memory limits
- **Networking**: Service types, ports
- **Provisioning**: Buckets, users, policies

Changes to `values.yaml` can be applied via Helm upgrade.

## Security Considerations

- Default passwords should be changed in production
- Credentials are stored in Kubernetes Secrets
- TLS/SSL should be configured for production use
- Network policies can be enabled to restrict access
- IAM policies follow principle of least privilege

## Development Workflow

1. Modify `values.yaml` to add/change resources
2. Test changes: `helm upgrade minio-standalone . -n minio-standalone`
3. Verify: Check buckets, users, policies via MinIO Console
4. Commit changes to version control

## Maintenance

- **Backup**: PersistentVolume contains all data
- **Upgrades**: Use `helm upgrade` to apply changes
- **Monitoring**: Check pod logs and MinIO Console metrics
- **Cleanup**: Use `./uninstall.sh` to remove all resources

## Related Documentation

- [Official MinIO Documentation](https://min.io/docs/minio/kubernetes/upstream/)
- [MinIO Helm Chart Repository](https://github.com/minio/minio/tree/master/helm/minio)
- [S3 API Compatibility](https://docs.min.io/docs/minio-server-limits-per-tenant.html)

## Agent Instructions

When working with this project:

1. **Configuration changes**: Edit `values.yaml` under the `minio:` key
2. **Adding buckets**: Add entries to `minio.buckets` list
3. **Adding users**: Add entries to `minio.users` list
4. **Adding policies**: Add entries to `minio.policies` list
5. **Image updates**: Modify `minio.image.tag` to use different MinIO versions
6. **Dependency updates**: Run `helm dependency update` after Chart.yaml changes
7. **Testing**: Use `./install.sh` or `helm upgrade` to apply changes
8. **Verification**: Use `kubectl exec` with `mc` commands to verify resources

## Project Status

✅ **Working**: MinIO server, Console UI, bucket/user/policy provisioning
✅ **Tested**: Minikube deployment, resource creation
✅ **Production considerations**: Requires password changes, TLS configuration, resource tuning
