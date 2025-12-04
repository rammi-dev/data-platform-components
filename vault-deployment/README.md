# HashiCorp Vault Deployment for MinIO Credentials

This Helm chart deploys HashiCorp Vault in development mode and automatically stores MinIO credentials for secure secret management. It demonstrates integration with the helm-secrets plugin for injecting Vault secrets into Helm deployments.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Usage](#usage)
- [Helm Secrets Integration](#helm-secrets-integration)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## 🎯 Overview

This deployment provides:
- **HashiCorp Vault** running in development mode for easy setup
- **Automated initialization** that stores MinIO credentials in Vault
- **Helm-secrets integration** examples for using Vault secrets in deployments
- **Ready-to-use scripts** for installation, verification, and cleanup

## ✨ Features

- ✅ Vault deployed via official HashiCorp Helm chart
- ✅ Development mode with auto-unsealing (root token: `root`)
- ✅ Automatic KV secrets engine v2 configuration
- ✅ MinIO credentials stored at `secret/minio` path
- ✅ Vault policies for secret access control
- ✅ Integration examples with helm-secrets plugin
- ✅ Comprehensive verification scripts

## 📦 Prerequisites

- Kubernetes cluster (minikube, kind, or any K8s cluster)
- `kubectl` configured to access your cluster
- `helm` v3.x installed
- (Optional) `helm-secrets` plugin for Vault integration

### Installing helm-secrets Plugin

```bash
helm plugin install https://github.com/jkroepke/helm-secrets
```

## 🚀 Quick Start

### 1. Install Vault

```bash
cd vault-deployment
chmod +x install.sh
./install.sh
```

The installation script will:
- Add HashiCorp Helm repository
- Update Helm dependencies
- Deploy Vault in development mode
- Run initialization job to store MinIO credentials
- Display access information

### 2. Verify Installation

```bash
chmod +x verify-vault.sh
./verify-vault.sh
```

This will check Vault status and display stored MinIO credentials.

### 3. Access Vault UI

```bash
# Port-forward to access Vault UI locally
kubectl port-forward deployment/vault-deployment-vault 8200:8200

# Open browser to http://localhost:8200
# Login with token: root
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│         Kubernetes Cluster                  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Vault Deployment                    │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  Vault Server (Dev Mode)       │  │  │
│  │  │  - KV Secrets Engine v2        │  │  │
│  │  │  - Auto-unsealed               │  │  │
│  │  │  - Root token: root            │  │  │
│  │  └────────────────────────────────┘  │  │
│  │                                      │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  Init Job (Post-Install)       │  │  │
│  │  │  - Enable KV v2 engine         │  │  │
│  │  │  - Store MinIO credentials     │  │  │
│  │  │  - Create policies             │  │  │
│  │  └────────────────────────────────┘  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  Vault Secrets:                             │
│  secret/minio/root                          │
│  ├── username: admin                        │
│  └── password: adminpassword123             │
│                                             │
│  secret/minio/users/default-minio           │
│  ├── accessKey: default-minio               │
│  ├── secretKey: defaultminio123             │
│  └── policy: minio-temporary-policy         │
└─────────────────────────────────────────────┘
```

## 💡 Usage

### Accessing Vault CLI

```bash
# Get Vault pod name
VAULT_POD=$(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

# Execute Vault commands
kubectl exec -it $VAULT_POD -- vault status
kubectl exec -it $VAULT_POD -- vault kv list secret/minio
kubectl exec -it $VAULT_POD -- vault kv get secret/minio/root
```

### Retrieving MinIO Credentials

```bash
# Get root credentials
kubectl exec -it $VAULT_POD -- vault kv get secret/minio/root

# Get user credentials
kubectl exec -it $VAULT_POD -- vault kv get secret/minio/users/default-minio

# Get credentials in JSON format
kubectl exec -it $VAULT_POD -- vault kv get -format=json secret/minio/root
```

### Adding New Secrets

```bash
# Add new MinIO user credentials
kubectl exec -it $VAULT_POD -- vault kv put secret/minio/users/newuser \
  accessKey=newuser \
  secretKey=newsecret123 \
  policy=custom-policy
```

## 🔐 Helm Secrets Integration

### Method 1: Using helm-secrets with Vault Backend

The `secrets.yaml` file demonstrates how to reference Vault secrets:

```yaml
vault:
  minio:
    root:
      username: vault:secret/data/minio/root#username
      password: vault:secret/data/minio/root#password
```

**Deploy MinIO with Vault secrets:**

```bash
# Set Vault environment variables
export VAULT_ADDR=http://vault-deployment-vault:8200
export VAULT_TOKEN=root

# Deploy using helm-secrets
helm secrets upgrade --install minio ../minio-standalone-1 \
  -f secrets.yaml
```

### Method 2: Direct Vault References in Values

See `../minio-standalone-1/minio-values-with-vault.yaml` for an example of using template variables that get populated from Vault.

### Method 3: Manual Secret Retrieval

```bash
# Retrieve secrets and use in deployment
MINIO_ROOT_USER=$(kubectl exec -it $VAULT_POD -- vault kv get -field=username secret/minio/root)
MINIO_ROOT_PASSWORD=$(kubectl exec -it $VAULT_POD -- vault kv get -field=password secret/minio/root)

# Use in helm install
helm upgrade --install minio ../minio-standalone-1 \
  --set minio.rootUser=$MINIO_ROOT_USER \
  --set minio.rootPassword=$MINIO_ROOT_PASSWORD
```

## 🔧 Troubleshooting

### Vault Pod Not Starting

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=vault

# Check pod logs
kubectl logs -l app.kubernetes.io/name=vault

# Describe pod for events
kubectl describe pod -l app.kubernetes.io/name=vault
```

### Init Job Failed

```bash
# Check init job status
kubectl get jobs -l app.kubernetes.io/component=vault-init

# View init job logs
kubectl logs -l app.kubernetes.io/component=vault-init

# Re-run init job (delete and reinstall)
kubectl delete job -l app.kubernetes.io/component=vault-init
helm upgrade --install vault-deployment .
```

### Cannot Access Vault

```bash
# Check Vault service
kubectl get svc vault-deployment-vault

# Test connectivity from within cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside pod:
apk add curl
curl http://vault-deployment-vault:8200/v1/sys/health
```

### Secrets Not Found

```bash
# List all secrets
kubectl exec -it $VAULT_POD -- vault kv list secret/

# Check if KV engine is enabled
kubectl exec -it $VAULT_POD -- vault secrets list

# Re-enable KV engine if needed
kubectl exec -it $VAULT_POD -- vault secrets enable -path=secret kv-v2
```

## 🔒 Security Considerations

### Development Mode Warnings

> **⚠️ IMPORTANT**: This deployment uses Vault in **development mode**, which is **NOT suitable for production**:

- Data is stored **in-memory** (lost on pod restart)
- Vault is **automatically unsealed** (no manual unsealing required)
- Root token is **hardcoded** to `root`
- TLS is **disabled**
- No high availability

### Production Deployment

For production use, you should:

1. **Disable dev mode** in `values.yaml`:
   ```yaml
   vault:
     server:
       dev:
         enabled: false
       standalone:
         enabled: true
       dataStorage:
         enabled: true
         size: 10Gi
   ```

2. **Enable TLS** for secure communication

3. **Configure proper unsealing** (auto-unseal with cloud KMS or manual unsealing)

4. **Use strong, random root token** and rotate it regularly

5. **Enable audit logging**:
   ```bash
   vault audit enable file file_path=/vault/audit/audit.log
   ```

6. **Implement proper RBAC** with Kubernetes service accounts

7. **Enable high availability** with multiple Vault replicas

8. **Use persistent storage** for Vault data

### Secret Management Best Practices

- **Rotate credentials** regularly
- **Use least-privilege policies** for secret access
- **Enable audit logging** to track secret access
- **Use namespaces** to isolate secrets
- **Implement secret versioning** (KV v2 provides this)
- **Never commit secrets** to version control

## 📚 Additional Resources

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Vault Helm Chart](https://github.com/hashicorp/vault-helm)
- [helm-secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [Vault Best Practices](https://www.vaultproject.io/docs/internals/security)

## 🗑️ Cleanup

To remove the Vault deployment:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will remove all Vault resources including the Helm release, init job, and service accounts.

## 📝 Files Overview

- `Chart.yaml` - Helm chart metadata
- `values.yaml` - Vault configuration values
- `templates/vault-init-job.yaml` - Initialization job for storing secrets
- `templates/_helpers.tpl` - Helm template helpers
- `install.sh` - Installation script
- `uninstall.sh` - Cleanup script
- `verify-vault.sh` - Verification script
- `secrets.yaml` - helm-secrets configuration example
- `../minio-standalone-1/minio-values-with-vault.yaml` - MinIO values with Vault integration

## 📄 License

This project follows the same license as the parent repository.
