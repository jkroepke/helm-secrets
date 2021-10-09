[![CI](https://github.com/jkroepke/helm-secrets/workflows/CI/badge.svg)](https://github.com/jkroepke/helm-secrets/)
[![License](https://img.shields.io/github/license/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/blob/main/LICENSE)
[![Current Release](https://img.shields.io/github/release/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/jkroepke/helm-secrets/total?logo=github)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/pulls)
[![codecov](https://codecov.io/gh/jkroepke/helm-secrets/branch/main/graph/badge.svg?token=4qAukyB2yX)](https://codecov.io/gh/jkroepke/helm-secrets)

# helm-secrets

## Usage

### Decrypt secrets via plugin command

Wraps the whole helm command. Slow on multiple value files.

```bash
helm secrets upgrade name . -f secrets.yaml
```

### Decrypt secrets via protocol handler

Run decrypted command on specific value files.

```bash
helm upgrade name . -f secrets://secrets.yaml
```

See: [docs/USAGE.md](docs/USAGE.md) for more information

### ArgoCD

For running helm-secrets with ArgoCD, see [docs/ARGOCD.md](docs/ARGOCD.md) for more information.

## Installation and Dependencies

### SOPS

If you use sops with helm-secrets, the sops CLI tool is needed.

You can install it manually using Homebrew:

```bash
brew install sops
```

Download: https://github.com/mozilla/sops/releases/latest

sops 3.2.0 is required at minimum.

### vals

[vals](https://github.com/variantdev/vals) is a tool for managing configuration values and secrets form various sources.

It supports various backends including:

* [Vault](https://github.com/variantdev/vals#vault)
* [AWS SSM Parameter Store](https://github.com/variantdev/vals#aws-ssm-parameter-store)
* [AWS Secrets Manager](https://github.com/variantdev/vals#aws-secrets-manager)
* [AWS S3](https://github.com/variantdev/vals#aws-s3)
* [GCP Secrets Manager](https://github.com/variantdev/vals#gcp-secrets-manager)
* [Azure Key Vault](https://github.com/variantdev/vals#azure-key-vault)
* [SOPS-encrypted files](https://github.com/variantdev/vals#sops)
* [Terraform State](https://github.com/variantdev/vals#terraform-tfstate)
* [Plain File](https://github.com/variantdev/vals#file)

All clients are integrated into vals, no additional tools required.

Download: https://github.com/variantdev/vals/releases/latest

### Hashicorp Vault

If you use Vault with helm-secrets, the vault CLI tool is needed.

You can install it manually using Homebrew:

```bash
brew install vault
```

Download: https://www.vaultproject.io/downloads

### envsubst

If you have stored you secret inside environment variables, you could use the envsubst driver.

```bash
brew install gettext
```

### Doppler

If you use [Doppler](https://doppler.com) with helm-secrets, the doppler CLI tool is needed.


```bash
brew install dopplerhq/cli/doppler
```

You need to make sure chart folder or parent one is in correct CLI's scope with enough access to project.

### SOPS git diff

Git config part is installed with the plugin, but to be fully functional the following needs to be added to the `.gitattributes` file in the root directory of a charts repo:

```
secrets.yaml diff=sopsdiffer
secrets.*.yaml diff=sopsdiffer
```

More info on [sops page](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)

By default, helm plugin install does this for you.

### Using Helm plugin manager

Install a specific version (recommend)
```bash
helm plugin install https://github.com/jkroepke/helm-secrets --version v3.9.1
```

Install latest unstable version from main branch
```bash
helm plugin install https://github.com/jkroepke/helm-secrets
```

Find the latest version here: https://github.com/jkroepke/helm-secrets/releases

### Manual installation

#### Latest version

Windows (inside cmd, needs to be verified)
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tar.gz | tar -C "%APPDATA%\helm\plugins" -xzf-
```
MacOS / Linux
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/latest/download/helm-secrets.tar.gz | tar -C "$(helm env HELM_PLUGINS)" -xzf-
```

#### Specific version

Windows (inside cmd, needs to be verified)
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/download/v3.9.1/helm-secrets.tar.gz | tar -C "%APPDATA%\helm\plugins" -xzf-
```
MacOS / Linux
```bash
curl -LsSf https://github.com/jkroepke/helm-secrets/releases/download/v3.9.1/helm-secrets.tar.gz | tar -C "$(helm env HELM_PLUGINS)" -xzf-
```

### Installation on Helm 2

Helm 2 doesn't support downloading plugins. Since unknown keys in `plugin.yaml` are fatal plugin installation needs special handling.

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

## Explicitly specify binary path
If sops is installed at the non-default location or if you have multiple versions of sops on your system, you can use `HELM_SECRETS_$DRIVER_PATH` to explicitly specify the sops binary to be used.

```bash
# Example for in-tree drivers via environment variable
HELM_SECRETS_SOPS_PATH=/custom/location/sops helm secrets view ./tests/assets/helm_vars/secrets.yaml
HELM_SECRETS_VALS_PATH=/custom/location/vals helm secrets view ./tests/assets/helm_vars/secrets.yaml
```

## Change secret driver

It's possible to use another secret driver then sops, e.g. Hasicorp Vault.

Start by a copy of [sops driver](https://github.com/jkroepke/helm-secrets/blob/main/scripts/drivers/sops.sh) and adjust to your own needs.

The custom driver can be load via `HELM_SECRETS_DRIVER` parameter or `-d` option (higher preference):

Example for in-tree drivers via option
```bash
helm secrets -d sops view ./tests/assets/helm_vars/secrets.yaml
```
Example for in-tree drivers via environment variable
```bash
HELM_SECRETS_DRIVER=vault helm secrets view ./tests/assets/helm_vars/secrets.yaml
```
Example for out-of-tree drivers
```bash
helm secrets -d ./path/to/driver.sh view ./tests/assets/helm_vars/secrets.yaml
```

Pull Requests are much appreciated.

The driver option is a global one. A file level switch isn't supported yet.

## Pass additional arguments to secret driver

```bash
helm secrets -a "--verbose" view ./tests/assets/helm_vars/secrets.yaml
```

results into:

```
[PGP]    INFO[0000] Decryption succeeded                          fingerprint=D6174A02027050E59C711075B430C4E58E2BBBA3
[SOPS]   INFO[0000] Data key recovered successfully
[SOPS]   DEBU[0000] Decrypting tree
[helm-secrets] Decrypt: tests/assets/values/sops/secrets.yaml
==> Linting examples/sops
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

[helm-secrets] Removed: tests/assets/values/sops/secrets.yaml.dec
```

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

### ArgoCD support

helm-secrets could detect an ArgoCD environment by the `ARGOCD_APP_NAME` environment variable. If detected, `HELM_SECRETS_QUIET` is set to `true`.

See [USAGE.md](./USAGE.md#argo-cd-integration) for example.

### Terraform support

The terraform helm provider does not [support downloader plugins](https://github.com/hashicorp/terraform-provider-helm).

An example how to use helm-secrets with terraform could be found in [contrib/terraform](contrib/terraform).

## Moving parts of project

- [`scripts/run.sh`](scripts/run.sh) - Main helm-secrets plugin code for all helm-secrets plugin actions available in `helm secrets help` after plugin install
- [`scripts/drivers`](scripts/drivers) - Location of the in-tree secrets drivers
- [`scripts/commands`](scripts/commands) - Sub Commands of `helm secrets` are defined here.
- [`scripts/lib`](scripts/lib) - Common functions used by `helm secrets`.
- [`scripts/wrapper`](scripts/wrapper) - Wrapper scripts for Windows systems.
- [`tests`](tests) - Test scripts to check if all parts of the plugin work. Using test assets with PGP keys to make real tests on real data with real encryption/decryption. See [`tests/README.md`](tests/README.md) for more informations.
- [`examples`](examples) - Some example secrets.yaml

## Copyright and license

© 2020-2021 [Jan-Otto Kröpke (jkroepke)](https://github.com/jkroepke/helm-secrets)

© 2017-2020 [Zendesk](https://github.com/zendesk/helm-secrets)

Licensed under the [Apache License, Version 2.0](LICENSE)
