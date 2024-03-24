## Gitea

```
[openid]
ENABLE_OPENID_SIGNIN = false
ENABLE_OPENID_SIGNUP = true
WHITELISTED_URIS     = auth.example.com

[service]
DISABLE_REGISTRATION                          = false
ALLOW_ONLY_EXTERNAL_REGISTRATION              = true
SHOW_REGISTRATION_BUTTON                      = false

[metrics]
ENABLED = true
ENABLED_ISSUE_BY_REPOSITORY = true
TOKEN = token
```

```bash
gitea admin auth add-oauth --name Keycloak --provider openidConnect --key gitea --secret <keycloak-oidc-secret> --auto-discover-url http://keycloak.localhost/realms/master/.well-known/openid-configuration
```

```bash
gitea admin auth list | grep Keycloak | awk '{print $1}'
```

```bash
gitea admin auth update-oauth --name MyKeycloak --provider openidConnect --key \
gitea --secret <keycloak-oidc-secret> --auto-discover-url \ 
http://keycloak.localhost/realms/master/.well-known/open id-configuration --id \
`gitea admin auth list | grep Keycloak | awk '{print $1}'`
```

```bash
gitea admin user create --username foobar --password password --email \ 
foobar@foobar.de --admin true --must-change-password false
```

Curl metrics

```bash
curl http://gitea.localhost/metrics -H "Accept: application/json" -H "Authorization: Bearer token"
```
