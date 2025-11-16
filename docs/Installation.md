# Installation

# Using Helm plugin manager

## Helm 4

Helm 4 introduced a new plugin system that requires splitting plugins into multiple packages when they have multiple capabilities. Therefore, `helm-secrets` is now distributed as three separate plugins:
- `helm-secrets`: The core plugin that provides the main functionality.
- `helm-secrets-getter`: A plugin that adds support for secret getters, e.g. `secrets://`.
- `helm-secrets-post-renderer`: A plugin that adds support for post-rendering.

### Verification

Verification of plugins is supported in Helm 4 and **enabled by default**. You can choose 
to verify the plugins during installation by omitting the `--verify=false` flag.

Public Key for verification can be found here: https://github.com/jkroepke.gpg

### Install a specific version (recommend).

The `--version` flag is not supported in Helm 4, so you need to specify the exact download URL for the desired version.

Click [here](https://github.com/jkroepke/helm-secrets/releases/latest) for the latest version.

```bash
helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.0/helm-secrets.tgz
helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.0/helm-secrets-getter.tgz
helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.0/helm-secrets-post-renderer.tgz
```

### Install latest version

```bash
helm plugin install https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tgz
helm plugin install https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets-getter.tgz
helm plugin install https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets-post-renderer.tgz
```

## Helm 3

Install a specific version (recommend). 
Click [here](https://github.com/jkroepke/helm-secrets/releases/latest) for the latest version.
```bash
helm plugin install https://github.com/jkroepke/helm-secrets --version v4.7.0
```

Install latest unstable version from main branch
```bash
helm plugin install https://github.com/jkroepke/helm-secrets
```

Find the latest version here: https://github.com/jkroepke/helm-secrets/releases/latest

See [Secret Backend manual](https://github.com/jkroepke/helm-secrets/wiki/Secret-Backends#list-of-implemented-secret-backends) for additional installation tasks.

# Manual installation

Works for Helm 2 and Helm 3.

## Latest version

Windows (inside cmd, need to be verified)
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tar.gz | tar -C "%APPDATA%\helm\plugins" -xzf-
```
MacOS / Linux
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tar.gz | tar -C "$(helm env HELM_PLUGINS)" -xzf-
```

## Specific version

Windows (inside cmd, need to be verified)
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/download/v3.12.0/helm-secrets.tar.gz | tar -C "%APPDATA%\helm\plugins" -xzf-
```
MacOS / Linux
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/download/v3.12.0/helm-secrets.tar.gz | tar -C "$(helm env HELM_PLUGINS)" -xzf-
```

# Helm 2

Helm 2 doesn't support downloading plugins. Since unknown keys in `plugin.yaml` are fatal plugin installation needs special handling.

Error on Helm 2 installation:

```
# helm plugin install https://github.com/jkroepke/helm-secrets
Error: yaml: unmarshal errors:
  line 12: field platformCommand not found in type plugin.Metadata
```

## Installation on Helm 2

1. Install helm-secrets via [manual installation](#manual-installation) but extract inside helm2 plugin directory e.g.: `$(helm home)/plugins/`
2. Strip `platformCommand` from `plugin.yaml` like:
   ```
   sed -i '/platformCommand:/,+2 d' "${HELM_HOME:-"${HOME}/.helm"}/plugins/helm-secrets*/plugin.yaml"
   ```
3. Done

Click [here](https://github.com/adorsys-containers/ci-helm/blob/f9a8a5bf8953ab876266ca39ccbdb49228e9f117/images/2.17/Dockerfile#L91), for an example!
