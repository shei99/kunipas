# ArgoCD - GitOps

## Official Documentation

[Documentation](https://argo-cd.readthedocs.io/en/stable/)

## Installation

- Add the helm repository

```bash
helm repo add argo https://argoproj.github.io/argo-helm
```

- Install ArgoCD stack

```bash
helm install argocd argo/argo-cd -n argocd --create-namespace -f values.yml
```

## Configuration

### OIDC

- First you'll need to encode the client secret in base64:

```bash
echo -n '83083958-8ec6-47b0-a411-a8c55381fbd2' | base64
```

- Then you can edit the secret and add the base64 value to a new key called
  `oidc.keycloak.clientSecret` using

```bash
kubectl edit secret argocd-secret
```

Your Secret should look something like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-secret
data:
  ...
  oidc.keycloak.clientSecret: ODMwODM5NTgtOGVjNi00N2IwLWE0MTEtYThjNTUzODFmYmQy
  ...
```

_Note:_ If there is an Error `cipher: message authentication failed`, reload the
`argocd-server` Deployment with
`kubectl rollout restart -n argocd deployment/argocd-server`

[Keycloak OIDC Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/keycloak/)

### AuthN and AuthZ

ArgoCD provides two different ways for this:

- RBAC for configuring roles for user / groups
- _AppProjects_ for configuring rules for applications

RBAC is generally configured in the _config-map_ `argocd-rbac-cm`. If your RBAC
roles are only scoped to one project, you can define them in the _AppProject_.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: tenant-01-project
  namespace: argocd
spec:
  roles:
    - name: tenant-01-admin
      description: Tenant 01 Admin role
      policies:
        - p, role:tenant-01-admin, applications, *, tenant-01-project/*, allow
        - p, role:tenant-01-admin, clusters, get, *, allow
        - p, role:tenant-01-admin, logs, get, tenant-01-project/*, allow
        - p, role:tenant-01-admin, projects, get, tenant-01-project, allow
        - p, role:tenant-01-admin, repositories, *, tenant-01-project/*, allow
        - g, tenant-01:admin, role:tenant-01-admin
      groups:
        - tenant-01:admin

    - name: tenant-01-user
      description: Tenant 01 User role
      policies:
        - p, role:tenant-01-user, applications, get, tenant-01-project/*, allow
        - p, role:tenant-01-user, applications, sync, tenant-01-project/*, allow
        - p, role:tenant-01-user, clusters, get, tenant-01, allow
        - p, role:tenant-01-user, logs, get, tenant-01-project/*, allow
        - p, role:tenant-01-user, projects, get, tenant-01-project, allow
        - g, tenant-01:user, role:tenant-01-user
      groups:
        - tenant-01:user

  sourceRepos:
    - "*"
  permitOnlyProjectScopedClusters: true
```

Additionally it is useful to configure a default policy and define a admin
group. This can be setup in the helm chart.

```yaml
configs:
  rbac:
    policy.csv: |
      g, Kunipas, role:admin
      p, role:none, *, *, */*, deny
    policy.default: "role:none"
```

Clusters and repositories can be configured to be project scoped. Therefore add
this to the _secrets_.

```yaml
kind: Secret
stringData:
  project: tenant-01-project
```

[RBAC policies](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
[AppProjects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects)

## Multi-Tenancy

**Problem:** The users need a way to deploy their software components into their
respective cluster. The solution should only allow tenants to deploy into
clusters, which they are authorized to.

### Shared Ressources

Deploy ArgoCD stack into the host / management cluster. Allow the tenants to
create _Application_ CRDs. But this has a caveat, the tenants have control on
which cluster the application can be depolyed to. There needs to be a policy in
place, which limits / enforces / regulates this. Kyverno can help to create
those policies.

**Pros:**

- Less ressources

**Cons:**

- More fragile configuration of RBAC (authentication & authorization)
- Needs third party policy engine (Kyverno or OPA)
  - _AppProject_ needs to be verified as well
- vCluster needs to sync the CRD into the Host Cluster (current alpha feature)
- it may be possible to change up the namespace, because the _Application(Set)_
  has to be synced to the namespace where ArgoCD is listening
- otherwise Kyverno can sync the ressources for the tenant namespace to the
  ArgoCD namespace
- Another difficulty is to automatically add the cluster. This can be done with
  the cli or a secret. A neat solution is to use Kyverno to create the secret.

When setting up the _Application_ CRDs, make sure you set the same cluster URL,
with which the cluster is configured.

[Kyverno cluster secret generation](https://piotrminkowski.com/2022/12/09/manage-multiple-kubernetes-clusters-with-argocd/)

### Dedicated Ressources

Deploy a ArgoCD stack per tenant into the (virtual) cluster. Tenants create
local _Application_ CRDs.

**Pros:**

- Easier RBAC (authentication & authorization on ArgoCD stack level)
- No need for any vCluster sync
- Tenants can selfmanage their groups, roles, _AppProject_

**Cons:**

- More ressources

[ArgoCD Multi-Tenancy](https://www.youtube.com/watch?v=HoVljPnJO1c)
