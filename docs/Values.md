# Values

helm-secrets natively support all values that are support by helm, including
[downloader plugins](https://helm.sh/docs/topics/plugins/#downloader-plugins).

# Remote values from http

When curl or wget is available, helm-secrets is able to fetch value files from various remote locations.

```bash
helm template -f secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/examples/sops/secrets.yaml
```

## Secured remote values

While helm does not support any authentication mechanism, helm-secret does support at least basic auth.
```bash
helm template -f secrets://https://user:password@raw.githubusercontent.com/jkroepke/helm-secrets/main/examples/sops/secrets.yaml
```

Additionally, the authentication details can be provided by environment variables or from a file system using the
[.netrc](https://everything.curl.dev/usingcurl/netrc) standard this is useful inside CD systems.


### Via environment variables

_Note: is feature is turned off by default and requires the environment variables `HELM_SECRETS_URL_VARIABLE_EXPANSION=true`._

```bash
# can be also defined via kubernetes PodSpec or CI secrets
export HELM_SECRETS_URL_VARIABLE_EXPANSION=true
export GH_TOKEN=ghp_xxxxxx 

helm template -f secrets://https://$${GH_TOKEN}@raw.githubusercontent.com/jkroepke/helm-secrets/main/examples/sops/secrets.yaml
```

### Via .netrc file

To enable this feature, an environment `NETRC` needs to defined which holds the path to the .netrc file. This is required
even the standard location `~/.netrc` is used. The .netrc file can hold multiple credentials for different hostnames.

The `wget` command on alpine linux does not support `.netrc` and `curl` is required and automatically preferred over `wget`.

Example `.netrc` file:

```
# cat .netrc
machine raw.githubusercontent.com
login ghp_xxxxxx
password
```

Then run

```bash
export NETRC="${PWD}/.netrc" # needs to be defined 
helm template -f secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/examples/sops/secrets.yaml
```

# Remote values from git

helm-secrets support [helm-git](https://github.com/aslafy-z/helm-git).
With this combination, you can fetch secret from other git repositories.

```bash
helm template -f secrets://git+https://[provider.com]/[user]/[repo]@[path/to/charts][?[ref=git-ref][&sparse=0][&depupdate=0]]
```

Other plugins like [helm-s3, helm-gcs](https://helm.sh/docs/community/related/#helm-plugins) are supported as well.

## Pass secrets through --set / --set-file

helm-secrets support pass secrets' trough `--set` or `--set-file`. 

Examples

```bash
helm secrets -b vals template bitnami/mysql --name-template mysql \
  --set auth.rootPassword=ref+vault://secret/mysql#/rootPassword
```

```bash
helm secrets template bitnami/mysql --name-template mysql \
  --set-file auth.rootPassword=secret.yaml
```

or through downloader syntax (`--set-file` only);

```bash
helm template bitnami/mysql --name-template mysql \
  --set-file auth.rootPassword=secrets://secret.yaml
```

## Ignore missing value files

If `HELM_SECRETS_IGNORE_MISSING_VALUES=true` is set, helm-secrets ignore all not found errors. This mimics ArgoCD's `ignoreMissingValueFile` setting.
Alternatively, if a value file beginnings with a question mark, all not found errors related to that values file only are ignored.

Example:

```bash
helm upgrade -i release . -f secrets://?dev/file-not-found.yaml
```
