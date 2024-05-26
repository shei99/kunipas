## Loki

### Multi-tenancy

1. Centralized approach:  
   Setup:
   - 1 centralized Grafana deployment
   - 1 centralized Loki deployment
   
   Steps:
   1. Create Grafana organizations
   2. Configure data sources in each organization (set X-Scope-OrgID Header)
   3. Update Promtail configuration

   Security is base on keeping the X-Scope-OrgID secret and thus making a GitOps approach difficult to use with the 
   Promtail config. Reason being the need to configure the tenant ids in the pipelineStages.
   <br><br>
   Improved soft tenancy:
   1. Create Grafana organizations
   2. Configure data sources in each organization (configure forward oauth)
   3. Configure Loki with oauth-proxy and set restriction on groups or use traefik with basic auth and use prom-label-proxy
      for restricting the tenant labels (X-Scope-OrgID)
   4. Update Promtail configuration (scrape only logs of applications in the tenant namespace)

   Security is **not** base on keeping the X-Scope-OrgID secret and thus making a GitOps approach easy to use with the
   Promtail config. The configuration can be checked into Git, because it does not contain secret data.
   But Loki needs to have an authentication mechanism so that other tenants can access only the tenants
   they are allowed to. Additionally, we need to restrict the tenant labels with prom-label-proxy.

   ```yml
   config:
    clients:
      - url: http://loki-gateway.universphere/loki/api/v1/push
        tenant_id: admins

    snippets:
      pipelineStages:
        - cri: {}
        - json:
            expressions:
              namespace:
        - labels:
            namespace:
        - match:
            selector: '{namespace="foo"}'
            stages:
              - tenant:
                  value: foo
        - match:
            selector: '{namespace="bar"}'
            stages:
              - tenant:
                  value: bar
        - output:
            source: message
   ```

2. Distributed approach:
   Setup:
   - 1 centralized Grafana deployment
   - n decentralized Loki deployment (per tenant one)
   - n decentralized Promtail deployment (per tenant one)

   Steps:
   1. Create Grafana organizations
   2. Configure data sources in each organization (configure forward oauth)
   3. Configure Loki with oauth-proxy and set restriction on groups or use traefik with basic auth
   4. Update Promtail configuration (scrape only logs of applications in the tenant namespace)

   Security is **not** base on keeping the X-Scope-OrgID secret and thus making a GitOps approach easy to use with the
   Promtail config. The configuration can be checked into Git, because it does not contain secret data.
   But Loki needs to have an authentication mechanism so that other tenants can access only the tenants
   they are allowed to.

   ```yml
   scrape_configs:
    - job_name: kubernetes-pods
      pipeline_stages:
         - cri: {}
      kubernetes_sd_configs:
         - role: pod
           namespaces:
              names:
                 - default
                 # - another-namespace
   ```