vault secrets enable --path kunipas kv-v2
vault policy write kunipas-minio - <<EOF
path "kunipas/data/minio/*" {
   capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/kunipas-thanos \
   bound_service_account_names=vso-kunipas-thanos \
   bound_service_account_namespaces=monitoring \
   policies=kunipas-minio \
   audience=vault \
   ttl=24h
