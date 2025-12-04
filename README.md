# as for hte helm value sinjector use only Vault Agnet injector remove other 

# Data Platform Components

A collection of Kubernetes-based data platform components deployed via Helm charts. This repository provides production-ready deployments for object storage (MinIO) and secret management (HashiCorp Vault) with secure integration patterns.

## 🎯 Purpose

This repository is designed for AI agents and developers to quickly deploy and integrate data platform infrastructure components. Each component is self-contained with automated installation scripts, comprehensive documentation, and integration examples.

## 📦 Components

### 1. MinIO Standalone (`minio-standalone-1/`)

Object storage server compatible with Amazon S3 API, deployed in standalone mode.

**Features:**
- Single-instance MinIO deployment
- Persistent storage with PVC
- Automated bucket and user provisioning
- Custom policy configuration
- MinIO Console UI access

**Quick Start:**
```bash
cd minio-standalone-1
./install.sh
```

**Key Files:**
- `values.yaml` - MinIO configuration
- `install.sh` - Automated installation
- `README.md` - Detailed documentation

### 2. Vault Deployment (`vault-deployment/`)

HashiCorp Vault deployment for secure secret management, pre-configured to store MinIO credentials.

**Features:**
- Vault in development mode (auto-unsealing)
- Automated secret initialization
- MinIO credentials stored in Vault KV v2
- helm-secrets plugin integration
- Vault policies for access control

**Quick Start:**
```bash
cd vault-deployment
./install.sh
```

**Key Files:**
- `values.yaml` - Vault configuration
- `install.sh` - Automated installation
- `verify-vault.sh` - Verification script
- `README.md` - Usage guide
- `VAULT_SETUP.md` - Advanced configuration

### 3. MinIO with Vault Integration (`minio-standalone-1/minio-values-with-vault.yaml`)

Example configuration showing how to deploy MinIO using credentials stored in Vault via helm-secrets plugin.

**Usage:**
```bash
# Set Vault environment
export VAULT_ADDR=http://vault-deployment-vault:8200
export VAULT_TOKEN=root

# Deploy MinIO with Vault secrets
cd minio-standalone-1
helm secrets upgrade --install minio . -f minio-values-with-vault.yaml
```

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster (minikube, kind, or any K8s cluster)
- `kubectl` configured to access your cluster
- `helm` v3.x or v4.x installed
- (Optional) Vault integration method (see [VAULT_INTEGRATION_ALTERNATIVES.md](VAULT_INTEGRATION_ALTERNATIVES.md))

> **Note on helm-secrets:** The `helm-secrets` plugin has compatibility issues with Helm v4. We recommend using **Vault Agent Injector** (included with Vault deployment) or **External Secrets Operator** instead. See [VAULT_INTEGRATION_ALTERNATIVES.md](VAULT_INTEGRATION_ALTERNATIVES.md) for details.

### Install Vault Integration (Choose One Method)

#### Method 1: Vault Agent Injector (Recommended, Already Included)
No additional installation needed! The Vault Agent Injector is already enabled in the vault-deployment.

#### Method 2: External Secrets Operator
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system --create-namespace
```

#### Method 3: Manual Secret Retrieval
No installation needed, just use kubectl/vault commands.

**See [VAULT_INTEGRATION_ALTERNATIVES.md](VAULT_INTEGRATION_ALTERNATIVES.md) for detailed setup and examples.**

### Deployment Order

For integrated setup with Vault-managed secrets:

1. **Deploy Vault first:**
   ```bash
   cd vault-deployment
   ./install.sh
   ./verify-vault.sh
   ```

2. **Install helm-secrets plugin:**
   ```bash
   cd ..
   ./install-helm-secrets.sh
   ```

3. **Deploy MinIO with Vault secrets:**
   ```bash
   cd minio-standalone-1
   export VAULT_ADDR=http://vault-deployment-vault:8200
   export VAULT_TOKEN=root
   helm secrets upgrade --install minio . -f minio-values-with-vault.yaml
   ```

### Standalone Deployment

To deploy components independently without Vault integration:

```bash
# MinIO only
cd minio-standalone-1
./install.sh

# Vault only
cd vault-deployment
./install.sh
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                         │
│                                                         │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  Vault           │         │  MinIO           │    │
│  │  - KV Secrets v2 │────────▶│  - S3 API        │    │
│  │  - Dev Mode      │ secrets │  - Console UI    │    │
│  │  - Auto-unseal   │         │  - Buckets       │    │
│  └──────────────────┘         └──────────────────┘    │
│         │                                               │
│         │ helm-secrets plugin                          │
│         ▼                                               │
│  ┌──────────────────┐                                  │
│  │  Secret Paths:   │                                  │
│  │  secret/minio/   │                                  │
│  │  ├── root        │                                  │
│  │  └── users/      │                                  │
│  └──────────────────┘                                  │
└─────────────────────────────────────────────────────────┘
```

## 📋 Repository Structure

```
data-platform-components/
├── minio-standalone-1/              # MinIO deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── minio-values-with-vault.yaml # Vault integration example
│   ├── templates/
│   ├── install.sh
│   ├── uninstall.sh
│   └── README.md
├── vault-deployment/                # Vault deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── secrets.yaml                 # helm-secrets example
│   ├── templates/
│   │   ├── vault-init-job.yaml     # Auto-initialization
│   │   └── _helpers.tpl
│   ├── install.sh
│   ├── verify-vault.sh
│   ├── uninstall.sh
│   ├── README.md
│   └── VAULT_SETUP.md
├── install-helm-secrets.sh          # Plugin installation
└── README.md                        # This file
```

## 🔐 Security Considerations

### Development vs Production

**Current Setup (Development):**
- ✅ Easy to deploy and test
- ✅ Auto-unsealing Vault
- ✅ Known credentials for quick setup
- ⚠️ In-memory Vault storage
- ⚠️ Hardcoded root token
- ⚠️ No TLS encryption

**For Production:**
- Enable persistent storage for Vault
- Configure auto-unseal with cloud KMS
- Enable TLS for all services
- Use strong, rotated credentials
- Implement proper RBAC
- Enable audit logging
- Deploy in HA mode

See `vault-deployment/VAULT_SETUP.md` for production configuration details.

## 🔧 Common Operations

### Access MinIO Console

```bash
kubectl port-forward -n default svc/minio-standalone-1 9001:9001
# Open http://localhost:9001
# Login: admin / adminpassword123
```

### Access Vault UI

```bash
kubectl port-forward -n default deployment/vault-deployment-vault 8200:8200
# Open http://localhost:8200
# Token: root
```

### Retrieve Secrets from Vault

```bash
VAULT_POD=$(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

# List secrets
kubectl exec -it $VAULT_POD -- vault kv list secret/minio

# Get MinIO root credentials
kubectl exec -it $VAULT_POD -- vault kv get secret/minio/root

# Get specific field
kubectl exec -it $VAULT_POD -- vault kv get -field=username secret/minio/root
```

### Update Secrets in Vault

```bash
# Update MinIO root password
kubectl exec -it $VAULT_POD -- vault kv put secret/minio/root \
  username=admin \
  password=newpassword123

# Add new user
kubectl exec -it $VAULT_POD -- vault kv put secret/minio/users/newuser \
  accessKey=newuser \
  secretKey=newsecret123 \
  policy=custom-policy
```

## 🧪 Testing

### Verify MinIO Deployment

```bash
cd minio-standalone-1
kubectl get pods -l app=minio
kubectl get svc minio-standalone-1
kubectl get pvc -l app=minio
```

### Verify Vault Deployment

```bash
cd vault-deployment
./verify-vault.sh
```

### Test S3 API Access

```bash
# Port-forward MinIO
kubectl port-forward svc/minio-standalone-1 9000:9000 &

# Use AWS CLI
aws --endpoint-url http://localhost:9000 \
    s3 ls \
    --profile minio
```

## 🗑️ Cleanup

### Remove All Components

```bash
# Uninstall MinIO
cd minio-standalone-1
./uninstall.sh

# Uninstall Vault
cd ../vault-deployment
./uninstall.sh

# Uninstall helm-secrets plugin (optional)
helm plugin uninstall secrets
```

## 📚 Additional Resources

- [MinIO Documentation](https://min.io/docs/minio/kubernetes/upstream/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [helm-secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

This repository is designed for easy extension. To add new components:

1. Create a new directory with component name
2. Include Helm chart with `Chart.yaml` and `values.yaml`
3. Add installation scripts (`install.sh`, `uninstall.sh`)
4. Provide comprehensive `README.md`
5. Update this main README with component details

## 📝 License

This project is provided as-is for educational and development purposes.

## 🔖 Version Information

- MinIO: RELEASE.2025-09-07T16-13-09Z
- MinIO Client: RELEASE.2024-11-21T17-21-54Z
- Vault: 1.18.2 (Helm chart v0.29.1)
- helm-secrets: v4.6.2
