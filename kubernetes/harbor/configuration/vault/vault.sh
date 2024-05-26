vault secrets enable --path kunipas kv-v2
vault policy write kunipas-harbor - <<EOF
path "kunipas/data/harbor/*" {
   capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/kunipas-harbor \
   bound_service_account_names=vso-kunipas-harbor \
   bound_service_account_namespaces=harbor \
   policies=kunipas-harbor \
   audience=vault \
   ttl=24h

vault kv put --mount=kunipas /harbor/core/admin HARBOR_ADMIN_PASSWORD="admin"
vault kv put --mount=kunipas /harbor/core/encryption secretKey="secretKey"
vault kv put --mount=kunipas /harbor/jobservice/jobservice JOBSERVICE_SECRET="jobserviceSecret"
vault kv put --mount=kunipas /harbor/registry/registry-http REGISTRY_HTTP_SECRET="registrySecret"
vault kv put --mount=kunipas /harbor/registry/registry-htpasswd REGISTRY_HTPASSWD="admin:$apr1$5Uw6Z2p9$Bq8mwQlM7W9qY3kgyUqWq/" REGISTRY_PASSWD="admin"
