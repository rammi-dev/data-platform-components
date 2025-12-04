# HashiCorp Vault Setup Guide

This guide provides detailed information about HashiCorp Vault concepts, configuration, and integration with Helm deployments.

## 📚 Table of Contents

- [Vault Concepts](#vault-concepts)
- [Secret Engines](#secret-engines)
- [Policies and Access Control](#policies-and-access-control)
- [Helm-Secrets Integration](#helm-secrets-integration)
- [Production Deployment](#production-deployment)
- [Advanced Usage](#advanced-usage)

## 🎓 Vault Concepts

### What is HashiCorp Vault?

HashiCorp Vault is a secrets management tool that provides:
- **Secure secret storage** - Encrypted storage for sensitive data
- **Dynamic secrets** - Generate secrets on-demand with automatic revocation
- **Data encryption** - Encrypt/decrypt data without storing it
- **Leasing and renewal** - All secrets have a lease with automatic revocation
- **Revocation** - Revoke secrets individually or in bulk

### Vault Architecture

```
┌─────────────────────────────────────────────────┐
│                 Vault Server                    │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │          Storage Backend                  │ │
│  │  (File, Consul, etcd, etc.)              │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         Secret Engines                    │ │
│  │  - KV (Key-Value)                        │ │
│  │  - Database                              │ │
│  │  - AWS, Azure, GCP                       │ │
│  │  - PKI, SSH, etc.                        │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         Auth Methods                      │ │
│  │  - Token, Kubernetes, LDAP, etc.         │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         Audit Devices                     │ │
│  │  - File, Syslog, Socket                  │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Vault Initialization and Unsealing

**Initialization** (one-time process):
- Generates master encryption key
- Creates unseal keys (Shamir's Secret Sharing)
- Generates initial root token

**Unsealing** (required after each restart):
- Vault starts in sealed state
- Requires threshold of unseal keys to decrypt master key
- In dev mode: automatically unsealed

**Sealing**:
- Vault can be manually sealed
- Clears master key from memory
- Requires unsealing to access secrets again

## 🔑 Secret Engines

### KV (Key-Value) Secrets Engine

The KV secrets engine is used for storing arbitrary secrets.

**Version 1 (KV v1)**:
- Simple key-value storage
- No versioning
- Immediate overwrites

**Version 2 (KV v2)** - Used in this deployment:
- Versioned secrets
- Configurable max versions
- Soft delete with undelete capability
- Metadata tracking

### KV v2 Path Structure

```
secret/                    # Mount path
├── data/                  # Actual secret data
│   └── minio/
│       ├── root
│       └── users/
│           └── default-minio
└── metadata/              # Secret metadata
    └── minio/
        ├── root
        └── users/
            └── default-minio
```

### Working with KV v2 Secrets

```bash
# Write a secret
vault kv put secret/myapp/config \
  username=admin \
  password=secret123

# Read a secret
vault kv get secret/myapp/config

# Read specific field
vault kv get -field=username secret/myapp/config

# List secrets
vault kv list secret/myapp

# Delete latest version (soft delete)
vault kv delete secret/myapp/config

# Undelete a version
vault kv undelete -versions=1 secret/myapp/config

# Permanently delete versions
vault kv destroy -versions=1 secret/myapp/config

# View secret metadata
vault kv metadata get secret/myapp/config

# View specific version
vault kv get -version=1 secret/myapp/config
```

## 🛡️ Policies and Access Control

### Vault Policies

Policies define what paths a user/application can access and what operations they can perform.

**Policy Capabilities**:
- `create` - Create new data
- `read` - Read data
- `update` - Update existing data
- `delete` - Delete data
- `list` - List keys
- `sudo` - Access root-protected paths
- `deny` - Explicitly deny access

### Example Policies

**Read-only policy for MinIO secrets**:
```hcl
# Allow reading MinIO secrets
path "secret/data/minio/*" {
  capabilities = ["read", "list"]
}

# Allow listing secret metadata
path "secret/metadata/minio/*" {
  capabilities = ["list"]
}
```

**Full access policy for MinIO secrets**:
```hcl
# Full access to MinIO secrets
path "secret/data/minio/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/minio/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

**Application-specific policy**:
```hcl
# Allow reading only root credentials
path "secret/data/minio/root" {
  capabilities = ["read"]
}

# Deny access to user credentials
path "secret/data/minio/users/*" {
  capabilities = ["deny"]
}
```

### Managing Policies

```bash
# Create a policy
vault policy write minio-readonly policy.hcl

# List policies
vault policy list

# Read a policy
vault policy read minio-readonly

# Delete a policy
vault policy delete minio-readonly
```

## 🔗 Helm-Secrets Integration

### Installing helm-secrets

```bash
# Install the plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Verify installation
helm secrets --help
```

### Configuring Vault Backend

Set environment variables for Vault access:

```bash
export VAULT_ADDR=http://vault-deployment-vault:8200
export VAULT_TOKEN=root

# For production, use more secure authentication:
export VAULT_ADDR=https://vault.example.com
export VAULT_TOKEN=$(vault login -token-only -method=kubernetes role=myapp)
```

### Secret Reference Syntax

helm-secrets uses special syntax to reference Vault secrets:

```
vault:PATH#FIELD
```

Where:
- `PATH` - Path to secret in Vault (including `/data/` for KV v2)
- `FIELD` - Field name within the secret

**Examples**:
```yaml
# Reference root username
username: vault:secret/data/minio/root#username

# Reference root password
password: vault:secret/data/minio/root#password

# Reference user access key
accessKey: vault:secret/data/minio/users/default-minio#accessKey
```

### Using helm-secrets in Deployments

**Method 1: Separate secrets file**

`secrets.yaml`:
```yaml
credentials:
  username: vault:secret/data/minio/root#username
  password: vault:secret/data/minio/root#password
```

Deploy:
```bash
helm secrets upgrade --install myapp ./chart -f secrets.yaml
```

**Method 2: Inline in values**

`values.yaml`:
```yaml
minio:
  rootUser: vault:secret/data/minio/root#username
  rootPassword: vault:secret/data/minio/root#password
```

Deploy:
```bash
helm secrets upgrade --install myapp ./chart -f values.yaml
```

**Method 3: Environment variable substitution**

```bash
# Export secrets as environment variables
export MINIO_USER=$(vault kv get -field=username secret/minio/root)
export MINIO_PASS=$(vault kv get -field=password secret/minio/root)

# Use in helm install
helm upgrade --install minio ./chart \
  --set minio.rootUser=$MINIO_USER \
  --set minio.rootPassword=$MINIO_PASS
```

## 🏭 Production Deployment

### Production Configuration

For production, update `values.yaml`:

```yaml
vault:
  server:
    # Disable dev mode
    dev:
      enabled: false
    
    # Enable standalone mode with persistent storage
    standalone:
      enabled: true
      config: |
        ui = true
        
        listener "tcp" {
          tls_disable = 0
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_cert_file = "/vault/userconfig/vault-tls/tls.crt"
          tls_key_file = "/vault/userconfig/vault-tls/tls.key"
        }
        
        storage "file" {
          path = "/vault/data"
        }
    
    # Enable persistent storage
    dataStorage:
      enabled: true
      size: 10Gi
      storageClass: "fast-ssd"
      accessMode: ReadWriteOnce
    
    # Enable audit logging
    auditStorage:
      enabled: true
      size: 5Gi
    
    # Resource limits
    resources:
      requests:
        memory: 512Mi
        cpu: 500m
      limits:
        memory: 2Gi
        cpu: 2000m
```

### High Availability Setup

For HA deployment:

```yaml
vault:
  server:
    # Enable HA mode
    ha:
      enabled: true
      replicas: 3
      raft:
        enabled: true
        setNodeId: true
        config: |
          ui = true
          
          listener "tcp" {
            tls_disable = 0
            address = "[::]:8200"
            cluster_address = "[::]:8201"
          }
          
          storage "raft" {
            path = "/vault/data"
          }
          
          service_registration "kubernetes" {}
```

### TLS Configuration

1. **Create TLS certificates**:
```bash
# Generate self-signed cert (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout vault.key -out vault.crt \
  -subj "/CN=vault.default.svc.cluster.local"

# Create Kubernetes secret
kubectl create secret tls vault-tls \
  --cert=vault.crt \
  --key=vault.key
```

2. **Mount TLS secret in Vault**:
```yaml
vault:
  server:
    volumes:
      - name: vault-tls
        secret:
          secretName: vault-tls
    volumeMounts:
      - name: vault-tls
        mountPath: /vault/userconfig/vault-tls
        readOnly: true
```

### Auto-Unseal with Cloud KMS

**AWS KMS**:
```yaml
vault:
  server:
    standalone:
      config: |
        seal "awskms" {
          region     = "us-west-2"
          kms_key_id = "alias/vault-unseal-key"
        }
```

**Azure Key Vault**:
```yaml
vault:
  server:
    standalone:
      config: |
        seal "azurekeyvault" {
          tenant_id      = "your-tenant-id"
          vault_name     = "your-keyvault-name"
          key_name       = "vault-unseal-key"
        }
```

**Google Cloud KMS**:
```yaml
vault:
  server:
    standalone:
      config: |
        seal "gcpckms" {
          project     = "your-project-id"
          region      = "us-central1"
          key_ring    = "vault"
          crypto_key  = "vault-unseal-key"
        }
```

## 🚀 Advanced Usage

### Kubernetes Authentication

Enable Kubernetes auth method for pod-based authentication:

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# Create a role for MinIO pods
vault write auth/kubernetes/role/minio \
  bound_service_account_names=minio \
  bound_service_account_namespaces=default \
  policies=minio-policy \
  ttl=24h
```

### Vault Agent Injector

Use Vault Agent Injector to automatically inject secrets into pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: minio
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "minio"
    vault.hashicorp.com/agent-inject-secret-credentials: "secret/minio/root"
    vault.hashicorp.com/agent-inject-template-credentials: |
      {{- with secret "secret/minio/root" -}}
      export MINIO_ROOT_USER="{{ .Data.data.username }}"
      export MINIO_ROOT_PASSWORD="{{ .Data.data.password }}"
      {{- end }}
spec:
  serviceAccountName: minio
  containers:
  - name: minio
    image: minio/minio
```

### Dynamic Database Credentials

Configure Vault to generate database credentials on-demand:

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  allowed_roles="minio-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/minio" \
  username="vault" \
  password="vaultpass"

# Create a role
vault write database/roles/minio-role \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" \
  max_ttl="24h"

# Generate credentials
vault read database/creds/minio-role
```

### Secret Rotation

Implement automatic secret rotation:

```bash
# Rotate root credentials
vault write -f sys/rotate

# Rotate database root credentials
vault write -f database/rotate-root/postgresql
```

### Audit Logging

Enable audit logging for compliance:

```bash
# Enable file audit device
vault audit enable file file_path=/vault/audit/audit.log

# Enable syslog audit device
vault audit enable syslog tag="vault" facility="LOCAL7"

# List audit devices
vault audit list

# Disable audit device
vault audit disable file/
```

## 📖 Additional Resources

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Vault API Reference](https://www.vaultproject.io/api-docs)
- [Vault Tutorials](https://learn.hashicorp.com/vault)
- [Vault on Kubernetes Guide](https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide)
- [helm-secrets Documentation](https://github.com/jkroepke/helm-secrets)
