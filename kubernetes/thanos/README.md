## Thanos

### Multi-tenancy
- Set `THANOS-TENANT: tenant` in the Prometheus remote write config
- Configure the querier with oauth-proxy and set restriction on groups or use traefik with basic auth. 
The querier has to be installed per tenant (per namespace).
- Configure the querier in grafana

Docs: https://thanos.io/tip/components/query.md/#tenancy \
https://github.com/thanos-io/tutorials/tree/main/6-multi-tenancy