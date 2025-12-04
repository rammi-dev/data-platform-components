# Vault Integration Alternatives

Since `helm-secrets` plugin has compatibility issues with Helm v4, here are recommended alternatives for integrating HashiCorp Vault with Kubernetes deployments.

## Licensing

**All solutions listed below are open-source and free to use:**

- ✅ **Vault Agent Injector** - Apache 2.0 License (part of HashiCorp Vault)
- ✅ **External Secrets Operator** - Apache 2.0 License
- ✅ **Vault Secrets Operator** - MPL 2.0 License (HashiCorp)
- ✅ **Manual Retrieval** - No additional software needed

All are production-ready and actively maintained by their respective communities.

## Recommended Solutions

### 1. **Vault Agent Injector** (Recommended for Most Use Cases)

The Vault Agent Injector automatically injects secrets from Vault into Kubernetes pods using annotations.

**Pros:**
- ✅ Built-in with Vault Helm chart
- ✅ No additional plugins needed
- ✅ Automatic secret rotation
- ✅ Works with any Helm chart

**How it works:**
Add annotations to your pod templates, and Vault automatically injects secrets at runtime.

**Example for MinIO:**
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
    command: ["/bin/sh", "-c"]
    args:
      - source /vault/secrets/credentials && minio server /data
```

**Setup:** Already included in the vault-deployment! Just enable the injector in values.yaml (already enabled by default).

---

### 2. **External Secrets Operator (ESO)**

ESO synchronizes secrets from Vault into Kubernetes Secret objects.

**Pros:**
- ✅ Supports multiple secret backends (Vault, AWS Secrets Manager, Azure Key Vault, etc.)
- ✅ Creates native Kubernetes Secrets
- ✅ Automatic synchronization
- ✅ Active community

**Installation:**
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace
```

**Example for MinIO:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault-deployment-vault:8200"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: "vault-token"
          key: "token"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: minio-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: minio-secret
    creationPolicy: Owner
  data:
  - secretKey: rootUser
    remoteRef:
      key: minio/root
      property: username
  - secretKey: rootPassword
    remoteRef:
      key: minio/root
      property: password
```

Then reference the secret in your Helm values:
```yaml
minio:
  rootUser:
    valueFrom:
      secretKeyRef:
        name: minio-secret
        key: rootUser
  rootPassword:
    valueFrom:
      secretKeyRef:
        name: minio-secret
        key: rootPassword
```

---

### 3. **Vault Secrets Operator**

HashiCorp's official Kubernetes operator for Vault.

**Pros:**
- ✅ Official HashiCorp solution
- ✅ Dynamic secret generation
- ✅ Automatic rotation
- ✅ Native Vault integration

**Installation:**
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault-secrets-operator hashicorp/vault-secrets-operator
```

**Example:**
```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: minio-credentials
spec:
  vaultAuthRef: default
  mount: secret
  type: kv-v2
  path: minio/root
  destination:
    name: minio-secret
    create: true
  refreshAfter: 1h
```

---

### 4. **Manual Secret Retrieval (Simple, No Plugin)**

For simple use cases, retrieve secrets manually and pass to Helm.

**Example:**
```bash
# Retrieve secrets from Vault
VAULT_POD=$(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
MINIO_USER=$(kubectl exec -it $VAULT_POD -- vault kv get -field=username secret/minio/root)
MINIO_PASS=$(kubectl exec -it $VAULT_POD -- vault kv get -field=password secret/minio/root)

# Deploy with Helm
helm upgrade --install minio ./minio-standalone-1 \
  --set minio.rootUser=$MINIO_USER \
  --set minio.rootPassword=$MINIO_PASS
```

---

## Comparison Table

| Solution | Complexity | Helm v4 Compatible | Auto-Rotation | Best For |
|----------|------------|-------------------|---------------|----------|
| **Vault Agent Injector** | Low | ✅ Yes | ✅ Yes | Most use cases, already included |
| **External Secrets Operator** | Medium | ✅ Yes | ✅ Yes | Multi-cloud, multiple secret backends |
| **Vault Secrets Operator** | Medium | ✅ Yes | ✅ Yes | Vault-only environments |
| **Manual Retrieval** | Very Low | ✅ Yes | ❌ No | Simple deployments, testing |
| **helm-secrets plugin** | Low | ❌ No (v4) | ❌ No | Helm v3 only, GitOps workflows |

---

## Recommended Approach for This Repository

For the `data-platform-components` repository, we recommend:

### **Option 1: Vault Agent Injector (Easiest)**
Already enabled in the vault-deployment. Just add annotations to MinIO deployment.

### **Option 2: External Secrets Operator (Most Flexible)**
Install ESO and create ExternalSecret resources for MinIO credentials.

### **Option 3: Manual Retrieval (Simplest)**
Use the script approach for quick deployments and testing.

---

## Migration from helm-secrets

If you were planning to use helm-secrets, here's how to migrate:

**From:**
```bash
helm secrets upgrade --install minio . -f secrets.yaml
```

**To (Vault Agent Injector):**
```bash
# Add annotations to your deployment template
# Then deploy normally
helm upgrade --install minio .
```

**To (External Secrets Operator):**
```bash
# Create ExternalSecret resource
kubectl apply -f external-secret.yaml
# Deploy normally
helm upgrade --install minio .
```

**To (Manual):**
```bash
# Run the retrieval script
./deploy-with-vault-secrets.sh
```

---

## Next Steps

1. Choose your preferred integration method
2. Follow the setup instructions above
3. Update your MinIO deployment accordingly
4. Test the integration

For detailed examples, see the vault-deployment/README.md and VAULT_SETUP.md files.
