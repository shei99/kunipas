# Monitoring

## Multi-Tenancy

**Problem:** The users need a way to deploy their software components into their
respective cluster. The solution should only allow tenants to deploy into
clusters, which they are authorized to.

### Shared Ressources

### Dedicated Ressources

# Prometheus - Monitoring

## Official Documentation

[Documentation](https://prometheus.io/docs/introduction/overview/)

## Installation

- Add the helm repository

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

- Install Prometheus

```bash
helm install prometheus prometheus-community/prometheus -f <values.yml>
```

## Configuration

### Prometheus scrape config

To scrape a multi line string, add `(?s)` in order for the `.` to also match the
newline character `n`.

```yaml
- source_labels: [__meta_kubernetes_pod_annotation_foo]
  action: replace
  regex: (?s)app.kubernetes.io.instance="([^"]*).*
  target_label: my_fancy_label_foo
- source_labels: [__meta_kubernetes_pod_annotation_bar]
  action: replace
  regex: (?s:app.kubernetes.io.instance="([^"]*).*)
```

## Multi-Tenancy

## Optimizations:

# Thanos - Monitoring

## Official Documentation

[Documentation](https://thanos.io/tip/thanos/getting-started.md/)

## Installation

- Add the helm repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

- Install Thanos

```bash
helm install thanos bitnami/thanos
```

## Configuration

## Setup

Thanos can be configured either with a remote read or remote write setup. A
combination of both is also possible.

### Remote Read (Pull based)

#### Architecture

- Multiple Prometheus instance with Thanos sidecar
- One Thanos Querier

#### Limitations

- Thanos sidecar and thus Prometheus needs to be exposed for querying
- Each sidcar needs Object Storage permissions
- Hard to design monitoring-as-a-service
- Not viable in resource constrained environments

### Remote Write (Push based)

#### Architecture

- Multiple Prometheus instance as Agents
- "One" Thanos Receiver
- One Thanos Querier

#### Limitations

- Hashring scaling for the Receivers
  - Either static
  - Or use the
    [thanos-receive-controller](https://github.com/observatorium/thanos-receive-controller)

## Multi-Tenancy

### Ingestion

- Set the HTTP Headers with the `THANOS-TENANT: example-tenant` which adds the
  `tenant_id="example-tenant"` label to the metric. This could be done in the
  remote write configuration of Prometheus.
- Set `--receive.limits-config-file` to set limits e.g. for `series_limit`,
  `size_bytes_limit` etc. (global or per tenant)

### Querier

- Set `--query.enforce-tenancy`, the query request needs to include the HTTP
  Header `THANOS-TENANT: example-tenant` (set label with prom-label-proxy or
  oauth2-proxy)
- Layered queries: Multi-Tenancy needs to be enforced on the first layer

[Tutorial](https://github.com/thanos-io/tutorials/tree/main/6-multi-tenancy)

## Optimizations:

- Write Path limits (active series limits)
- Set Ketama Hashring on Thanos Routing Receiver
  (`--receive.hashrings-algorithm=ketama`) Receive Controller
  (`--allow-only-ready-replicas`, `--allow-dynamic-scaling`) for autoscaling of
  Thanos Receivers [Talk](https://www.youtube.com/watch?v=5MJqdJq41Ms)
  [Repo](https://github.com/squat/kubeconeu2020)
- Distributed Executions
- Set the replication level (Quorum) for the Thanos Receiver
  (`--receive.replication-factor=3`) & pair it with Pod Disruption Budget
  (`Deployment.spec.maxUnavailable`) & use Thanos Compactor to deduplicate the
  data
- Thanos Compactor: Make sure to disable hierarchical namespace for Blob/Object
  Storage

Talk: https://www.youtube.com/watch?v=SAyPQ2d8v4Q Talk:
https://www.youtube.com/watch?v=2GokLB5_VfY Talk:
https://www.youtube.com/watch?v=Q3qOZ7SEgcM
