[![CI](https://github.com/jkroepke/helm-secrets/workflows/CI/badge.svg)](https://github.com/jkroepke/helm-secrets/)
[![License](https://img.shields.io/github/license/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/blob/master/LICENSE)
[![Current Release](https://img.shields.io/github/release/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![Production Ready](https://img.shields.io/badge/production-ready-green.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/pulls)

# helm-secrets

## This is a fork of futuresimple/helm-secrets or zendesk/helm-secrets?

Yes. This repository is a fork of [zendesk/helm-secrets](https://github.com/zendesk/helm-secrets) (base commit [edffea3c94c9ed70891f838b3d881d3578f2599f](https://github.com/jkroepke/helm-secrets/commit/edffea3c94c9ed70891f838b3d881d3578f2599f)).

This original helm-secrets project gets [abandoned](https://github.com/zendesk/helm-secrets/issues/100) and officially [deprecated](https://github.com/zendesk/helm-secrets/pull/168). I used this projects on my customer projects, and I also want to learn how unit tests for a shell language works.

In meanwhile, this project is officially listed on the [community projects side](https://helm.sh/docs/community/related/) at the helm documentation.

## Usage

### Decrypt secrets via plugin command

Wraps the whole helm command. Slow on multiple value files.
```
helm secrets upgrade name . -f secrets.yaml
```

### Decrypt secrets via protocol handler

Run decrypted command on specific value files.
```
helm upgrade name . -f secrets://secrets.yaml
```

See: [USAGE.md](USAGE.md) for more information

## Installation and Dependencies

### SOPS

Just install the plugin using `helm plugin install https://github.com/jkroepke/helm-secrets` and sops will be installed if possible as part of it.

You can always install manually in MacOS as below:

```bash
brew install sops
```

For Linux RPM or DEB, sops is available here: [Dist Packages](https://github.com/mozilla/sops/releases)

For Windows, you cloud install sops separate to mange secrets. This plugin doesn't support Windows yet. See: [#7](https://github.com/jkroepke/helm-secrets/issues/7)

#### Override version of sops

By override `SOPS_VERSION`, you could install a custom sops version of sops.

```bash
SOPS_VERSION=v3.6.0 SOPS_LINUX_SHA=610fca9687d1326ef2e1a66699a740f5dbd5ac8130190275959da737ec52f096 helm plugin install https://github.com/jkroepke/helm-secrets
```

#### Skip sops installation

It's possible to skip the automatic sops installation by defining `SKIP_SOPS_INSTALL=true` on the `helm plugin install` command, e.g:

```bash
SKIP_SOPS_INSTALL=true helm plugin install https://github.com/jkroepke/helm-secrets
```

### Hashicorp Vault

If you use Vault with helm-secret, the vault CLI is needed.

You can always install it manually in MacOS as below:

```bash
brew install vault
```

Download: https://www.vaultproject.io/downloads

### SOPS git diff

Git config part is installed with the plugin, but to be fully functional the following needs to be added to the `.gitattributes` file in the root directory of a charts repo:

```
secrets.yaml diff=sopsdiffer
secrets.*.yaml diff=sopsdiffer
```

More info on [sops page](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)

By default, helm plugin install does this for you.

### Using Helm plugin manager

```bash
# Install a specific version (recommend)
helm plugin install https://github.com/jkroepke/helm-secrets --version v3.3.0

# Install latest unstable version from master branch
helm plugin install https://github.com/jkroepke/helm-secrets
```

Find the latest version here: https://github.com/jkroepke/helm-secrets/releases

### Manual installation

#### Latest version

```bash
# Windows (inside cmd, needs to be verified)
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tar.gz | tar -C "%APPDATA%\helm\plugins" -xzf-

# MacOS / Linux
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tar.gz | tar -C "$(helm env HELM_PLUGINS)" -xzf-
```

#### Specific version

```bash
# Windows (inside cmd, needs to be verified)
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/download/v3.3.4/helm-secrets.tar.gz | tar -C "%APPDATA%\helm\plugins" -xzf-

# MacOS / Linux
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/download/v3.3.4/helm-secrets.tar.gz | tar -C "$(helm env HELM_PLUGINS)" -xzf-
```

### Installation on Helm 2

Helm 2 doesn't support downloader plugins. Since unknown keys in `plugin.yaml` are fatal, then plugin installation need special handling.

Error on Helm 2 installation:
```
# helm plugin install https://github.com/jkroepke/helm-secrets
Error: yaml: unmarshal errors:
  line 12: field platformCommand not found in type plugin.Metadata
```

Workaround:

1. Install helm-secrets via [manual installation](README.md#manual-installation), but extract inside helm2 plugin directory e.g.: `$(helm home)/plugins/`
2. Strip `platformCommand` from `plugin.yaml` like:
   ```
   sed -i '/platformCommand:/,+2 d' "${HELM_HOME:-"${HOME}/.helm"}/plugins/helm-secrets*/plugin.yaml"
   ```
3. Done

Client [here](https://github.com/adorsys-containers/ci-helm/blob/f9a8a5bf8953ab876266ca39ccbdb49228e9f117/images/2.17/Dockerfile#L91) for an example!

## Change secret driver

It's possible to use another secret driver then sops, e.g. Hasicorp Vault.

Start by a copy of [sops driver](https://github.com/jkroepke/helm-secrets/blob/master/scripts/drivers/sops.sh) and adjust to your own needs.

The custom driver can be load via `SECRET_DRIVER` parameter or `-d` option (higher preference):

```bash
# Example for in-tree drivers via option
helm secrets -d sops view ./tests/assets/helm_vars/secrets.yaml

# Example for in-tree drivers via environment variable
SECRET_DRIVER=vault helm secrets view ./tests/assets/helm_vars/secrets.yaml

# Example for out-of-tree drivers
helm secrets -d ./path/to/driver.sh view ./tests/assets/helm_vars/secrets.yaml
```

Pull Requests are much appreciated.

The driver option is a global one. A file level switch isn't supported yet.

## Main features

The current version of this plugin using [mozilla/sops](https://github.com/mozilla/sops/) by default as backend.

[Hashicorp Vault](http://vaultproject.io/) is supported as secret source since v3.2.0, too. In addition, [sops support vault since v3.6.0 natively](https://github.com/mozilla/sops#encrypting-using-hashicorp-vault). 

What kind of problems this plugin solves:

- Simple replaceable layer integrated with helm command for encrypting, decrypting, view secrets files stored in any place.
- On the fly decryption and cleanup for helm install/upgrade with a helm command wrapper

If you are using sops (used by default) you have some additional features:

- [Support for YAML/JSON structures encryption - Helm YAML secrets files](https://github.com/mozilla/sops#important-information-on-types)
- [Encryption per value where visual Diff should work even on encrypted files](https://github.com/mozilla/sops/blob/master/example.yaml)
- [On the fly decryption for git diff](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)
- [Multiple key management solutions like PGP, AWS KMS and GCP KMS at same time](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
- [Simple adding/removing keys](https://github.com/mozilla/sops#adding-and-removing-keys)
- [With AWS KMS permissions management for keys](https://aws.amazon.com/kms/)
- [Secrets files directory tree separation with recursive .sops.yaml files search](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
- [Extracting sub-elements from encrypted file structure](https://github.com/mozilla/sops#extract-a-sub-part-of-a-document-tree)
- [Encrypt only part of a file if needed](https://github.com/mozilla/sops#encrypting-only-parts-of-a-file). [Example encrypted file](https://github.com/mozilla/sops/blob/master/example.yaml)

An additional documentation, resources and examples can be found [here](USAGE.md).

## Moving parts of project

* [`scripts/install.sh`](scripts/install.sh) - Script used as the hook to download and install sops and install git diff configuration for helm-secrets files.
* [`scripts/run.sh`](scripts/run.sh) - Main helm-secrets plugin code for all helm-secrets plugin actions available in `helm secrets help` after plugin install
* [`scripts/drivers`](scripts/drivers) - Location of the in-tree secrets drivers
* [`scripts/commands`](scripts/commands) - Sub Commands of `helm secrets` are defined here.
* [`scripts/install.sh`](scripts/install.sh) - Script used as the hook to download and install sops and install git diff configuration for helm-secrets files.
* [`tests`](tests) - Test scripts to check if all parts of the plugin work. Using test assets with PGP keys to make real tests on real data with real encryption/decryption. See [`tests/README.md`](tests/README.md) for more informations.
* [`examples`](examples) - Some example secrets.yaml 

## Copyright and license

© 2020 [Jan-Otto Kröpke (jkroepke)](https://github.com/jkroepke/helm-secrets)

© 2017-2020 [Zendesk](https://github.com/zendesk/helm-secrets)

Licensed under the [Apache License, Version 2.0](LICENSE)
