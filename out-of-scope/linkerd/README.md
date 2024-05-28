# Linkerd

### Installation:

Create trust-anchor certificate pair (root ca) and create a secret out of it.

```bash
mkdir -p trust-anchor
step certificate create root.linkerd.cluster.local trust-anchor/ca.crt trust-anchor/ca.key \
  --profile root-ca --no-password --insecure --not-after=87600h &&
  kubectl create secret tls \
    linkerd-trust-anchor \
    --cert=trust-anchor/ca.crt \
    --key=trust-anchor/ca.key \
    --namespace=linkerd
```

Create the issuer

```bash
kubectl apply -f cert-manager/issuer.yml
```

Create the certificate

```bash
kubectl apply -f cert-manager/certificate.yml
```

Note: To allow the usage of snippets in nginx ingress controller add:

```
allow-snippet-annotations: "true"
```

### Setup PKI with vault, cert-manager, trust-manager

```bash
export VAULT_ADDR=http://vault.minikube
```

```bash
vault login <token>
```

Enable pki secrets engine

```bash
vault secrets enable --path pki_int pki
```

```bash
vault write pki_int/config/urls \
    issuing_certificates="http://vault.vault:8200/v1/pki_int/ca" \
    crl_distribution_points="http://vault.vault:8200/v1/pki_int/crl"
```

Create Policies

```bash
vault policy write pki_int - <<EOF
path "pki_int*"                { capabilities = ["read", "list"] }
path "pki_int/sign/linkerd"    { capabilities = ["create", "update"] }
path "pki_int/issue/linkerd"   { capabilities = ["create"] }
path "pki_int/root/sign-intermediate" { capabilities = ["create", "update" ] }
EOF
```

```bash
vault write pki_int/roles/linkerd \
    allowed_domains=linkerd.cluster.local \
    allow_subdomains=true \
    max_ttl=72h \
    key_type=any
```

```bash
vault auth enable kubernetes
```

```bash
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

Create authentication with service account

```bash
vault write auth/kubernetes/role/linkerd-vault-issuer \
    bound_service_account_names=vault-issuer \
    bound_service_account_namespaces=linkerd \
    audience="vault://linkerd/vault-issuer" \
    policies=pki_int \
    ttl=10m
```

Create root CA for trust-anchor

```bash
CERT=$(vault write -field=certificate pki_int/root/generate/internal \
      common_name=root.linkerd.cluster.local \
      ttl=2160h key_type=ec)
echo "$CERT" | step certificate inspect -
```
