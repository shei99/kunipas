## Cert-Manager

```bash
helm repo add jetstack https://charts.jetstack.io
```

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml
```

```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.4 \
```

```bash
kubectl apply -f cluster-issuer-staging.yml
```
