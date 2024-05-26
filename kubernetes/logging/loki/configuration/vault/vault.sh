vault secrets enable --path kunipas kv-v2
vault policy write kunipas-loki - <<EOF
path "kunipas/data/minio/*" {
   capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/kunipas-loki \
   bound_service_account_names=vso-kunipas-loki \
   bound_service_account_namespaces=logging \
   policies=kunipas-loki \
   audience=vault \
   ttl=24h

vault kv put --mount=kunipas /minio/admin MINIO_ROOT_USER="minio" MINIO_ROOT_PASSWORD="minio123"

