# Vault Secrets Operator

### Installation

Install the necessary CRDs

```bash
helm show crds hashicorp/vault-secrets-operator | kubectl apply -f -
```

Resources:

- https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator#rotate-the-static-secret
- https://github.com/hashicorp-education/learn-vault-secrets-operator
- https://www.youtube.com/watch?v=ECa8sAqE7M4
