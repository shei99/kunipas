# Loki - Logging

## Official Documentation

[Documentation](https://grafana.com/docs/loki/latest/)

## Installation

- Even without deploying the Grafana Agent, you need to install the
  [CRDs](https://github.com/grafana/agent/tree/main/operations/agent-static-operator/crds)

- Add the helm repository

```
helm repo add grafana https://grafana.github.io/helm-charts
```

- Install Loki

```bash
helm install loki grafana/loki
```

## Configuration

## Multi-Tenancy

**Problem:** The users need a way to deploy their software components into their
respective cluster. The solution should only allow tenants to see their logs,
which they are authorized to.

### Centralized approach:

Setup:

- 1 centralized Grafana deployment
- 1 centralized Loki deployment

Steps:

1. Create Grafana organizations
2. Configure data sources in each organization (set X-Scope-OrgID Header)
3. Update Promtail configuration

Security is base on keeping the X-Scope-OrgID secret and thus making a GitOps
approach difficult to use with the Promtail config. Reason being the need to
configure the tenant ids in the pipelineStages.

Improved soft tenancy:

1. Create Grafana organizations
2. Configure data sources in each organization (configure forward oauth)
3. Configure Loki with oauth-proxy and set restriction on groups or use traefik
   with basic auth and use prom-label-proxy for restricting the tenant labels
   (X-Scope-OrgID)
4. Update Promtail configuration (scrape only logs of applications in the tenant
   namespace)

Security is **not** base on keeping the X-Scope-OrgID secret and thus making a
GitOps approach easy to use with the Promtail config. The configuration can be
checked into Git, because it does not contain secret data. But Loki needs to
have an authentication mechanism so that other tenants can access only the
tenants they are allowed to. Additionally, we need to restrict the tenant labels
with prom-label-proxy.

### Distributed approach:

Setup:

- 1 centralized Grafana deployment
- n decentralized Loki deployment (per tenant one)
- n decentralized Promtail deployment (per tenant one)

Steps:

1. Create Grafana organizations
2. Configure data sources in each organization (configure forward oauth)
3. Configure Loki with oauth-proxy and set restriction on groups or use traefik
   with basic auth
4. Update Promtail configuration (scrape only logs of applications in the tenant
   namespace)

Security is **not** base on keeping the X-Scope-OrgID secret and thus making a
GitOps approach easy to use with the Promtail config. The configuration can be
checked into Git, because it does not contain secret data. But Loki needs to
have an authentication mechanism so that other tenants can access only the
tenants they are allowed to.

## Optimizations:

- High cardinality problem Each label combination
  `{app="nginx", label="foo", node="abc"}` a new stream gets created. The higher
  the label cardinality the more streams get created. Solution: Drop labels with
  high cardinality (eg. IP, node name)
- Rate limits Solution: set the rate and burst limit of the Ingesters
- Ingester Issue
  - Out of memory: Due to to manny streams (High cardinality problem) Solution:
    Drop label
  - Out of memory: Due to unequal volume of specific streams (some ingester had
    higher load then others) Solution: Shard the stream
  - Unhealthy ingester Solution: 'autoforget_unhealthy' switch on
- S3 Rate limits Solution: limit requests to S3 and increase chunk size, max
  chunk pagech
- Querying Issue Timeouts while querying Solution: Increase timeout limit

Cite: https://www.youtube.com/watch?v=sDI6h51s8KA&t=675s

# Promtail - Log Agent

## Official Documentation

[Documentation](https://grafana.com/docs/loki/latest/send-data/promtail/)

## Installation

- Add the helm repository

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

- Install Loki

```bash
helm install promtail grafana/promtail
```

## Multi-Tenancy

### Centralized approach:

```yaml
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

### Decentralized approach:

```yaml
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

## Configuration

vCluster adds some nested annotations like:

```lang
vcluster.loft.sh/labels:
  app.kubernetes.io/instance="kafka"
  app.kubernetes.io/managed-by="strimzi-cluster-operator"
  ...
```

To parse e.g. `kafka` from the annotation `app.kubernetes.io/instance`, you can
use the following regex.

```yaml
- source_labels: [__meta_kubernetes_pod_annotation_<name>]
  action: replace
  regex: (?s)app.kubernetes.io.instance="([^"]*).*
  # or
  regex: (?s:app.kubernetes.io.instance="([^"]*).*)
  target_label: my_label
```

# Resources:

[Blog](https://medium.com/otomi-platform/multi-tenancy-with-loki-promtail-and-grafana-demystified-e93a2a314473)
