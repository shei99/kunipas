vault secrets enable --path kunipas kv-v2
vault policy write kunipas-minio - <<EOF
path "kunipas/data/minio/*" {
   capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/kunipas-minio \
   bound_service_account_names=vso-kunipas-minio \
   bound_service_account_namespaces=s3 \
   policies=kunipas-minio \
   audience=vault \
   ttl=24h

vault kv put --mount=kunipas /minio/admin MINIO_ROOT_USER="minio" MINIO_ROOT_PASSWORD="minio123"

