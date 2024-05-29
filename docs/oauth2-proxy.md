# OAuth2-Proxy - AuthN and AuthZ

## Official Documentation

[Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)

## Installation

You can add the proxy as a sidecar to the relevant pods or deploy a the proxy
standalone.

- Add the helm repository

```
helm repo add oauth2-proxy https://oauth2-proxy.github.io/manifests
```

- Install OAuth2-Proxy

```bash
helm install oauth2-proxy oauth2-proxy/oauth2-proxy -f <values.yml>
```

## Configuration

There are two functionalities that the OAuth2-Proxy offers:

- validating jwt tokens
- authentication of a user with a cookie (eg. against an OIDC provider)

Further reading:
[Blog](https://medium.com/in-the-weeds/service-to-service-authentication-on-kubernetes-94dcb8216cdc)

### JWT Token

This works with setting the `--skip-jwt-bearer-tokens` configuration.
OAuth2-Proxy is looking for the `Authorization: Bearer <jwt-access-token>`. If
the token is valid the request is considered valid and can pass the proxy to the
upstream. This functionality can be use for adding datasources to Grafana with
Forward OAuth that are protected by OAuth2-Proxy. The configured in this JWT
there has to be the audience (with the name of the OIDC client from the
OAuth2-Proxy). This is relevant, if you use different clients for grafana and
your datasource.

[Docker example](https://github.com/shei99/kunipas/commit/68283aa8857377028341e7a2c38f701e2881dd56)

### Cookies

To configure OAuth2-Proxy to authenticate a user, use this setting. The proxy
starts the authentication flow, redirects the user to the configured provider
(eg. Keycloak with OIDC) and then the user logs in with his credentials. After a
successfull login, OAuth2-Proxy sets a cookie or cookie-ticket that identifies
the session. If the session is valid the request is considered valid and can
pass the proxy to the upstream.

[GitHub example Nginx](https://github.com/weinong/k8s-dashboard-with-aks-aad)
[Istio example Nginx](https://www.ventx.de/blog/post/istio_oauth2_proxy/index.html)
[GitHub example Traefik](https://www.leejohnmartin.co.uk/infrastructure/kubernetes/2022/05/31/traefik-oauth-proxy.html)

## Useful commands

Create a JWT for a service account

```bash
kubectl create token <service-account> --duration 60m --audience <audience>
```

Create a container and get the associated JWT with the (default) service account

```bash
kubectl run \
--restart=Never busybox -it \
--image=busybox --rm --quiet -- \
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```
