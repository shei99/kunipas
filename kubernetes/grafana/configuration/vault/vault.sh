vault secrets enable --path kunipas kv-v2
vault policy write kunipas-grafana - <<EOF
path "/kunipas/data/grafana/*" {
   capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/kunipas-grafana \
   bound_service_account_names=vso-kunipas-grafana \
   bound_service_account_namespaces=grafana \
   policies=kunipas-grafana \
   audience=vault \
   ttl=24h

vault kv put --mount=kunipas /grafana/admin admin-user="admin" admin-password="password"
vault kv put --mount=kunipas /grafana/oidc GF_AUTH_GENERIC_OAUTH_CLIENT_ID="grafana" GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=""
