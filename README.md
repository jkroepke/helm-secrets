[![CI](https://github.com/jkroepke/helm-secrets/workflows/CI/badge.svg)](https://github.com/jkroepke/helm-secrets/)
[![License](https://img.shields.io/github/license/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/blob/master/LICENSE)
[![Current Release](https://img.shields.io/github/release/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![Production Ready](https://img.shields.io/badge/production-ready-green.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/pulls)

# helm-secrets

## Main features

The current version of this plugin using by default [sops](https://github.com/mozilla/sops/) as backend.

[Hashicorp Vault](http://vaultproject.io/) is supported as secret source since v4.0.0, too.

What kind of problems this plugin solves:

- Simple replaceable layer integrated with helm command for encrypting, decrypting, view secrets files stored in any place.
- On the fly decryption and cleanup for helm install/upgrade with a helm command wrapper

If you are using sops you have some additional features:

- [Support for YAML/JSON structures encryption - Helm YAML secrets files](https://github.com/mozilla/sops#important-information-on-types)
- [Encryption per value where visual Diff should work even on encrypted files](https://github.com/mozilla/sops/blob/master/example.yaml)
- [On the fly decryption for git diff](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)
- [Multiple key management solutions like PGP, AWS KMS and GCP KMS at same time](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
- [Simple adding/removing keys](https://github.com/mozilla/sops#adding-and-removing-keys)
- [With AWS KMS permissions management for keys](https://aws.amazon.com/kms/)
- [Secrets files directory tree separation with recursive .sops.yaml files search](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
- [Extracting sub-elements from encrypted file structure](https://github.com/mozilla/sops#extract-a-sub-part-of-a-document-tree)
- [Encrypt only part of a file if needed](https://github.com/mozilla/sops#encrypting-only-parts-of-a-file). [Example encrypted file](https://github.com/mozilla/sops/blob/master/example.yaml)

Additional documentation, resources and examples can be found [here](USAGE.md).

## Moving parts of project

* [`scripts/install.sh`](scripts/install.sh) - Script used as the hook to download and install sops and install git diff configuration for helm-secrets files.
* [`scripts/run.sh`](scripts/run.sh) - Main helm-secrets plugin code for all helm-secrets plugin actions available in `helm secrets help` after plugin install
* [`tests`](tests) - Test scripts to check if all parts of the plugin work. Using test assets with PGP keys to make real tests on real data with real encryption/decryption.
* [`examples`](examples) - Some example secrets.yaml 

## Installation and Dependencies

### SOPS

Just install the plugin using `helm plugin install https://github.com/jkroepke/helm-secrets` and sops will be installed if possible as part of it.

You can always install manually in MacOS as below:

```bash
brew install sops
```

For Linux RPM or DEB, sops is available here: [Dist Packages](https://github.com/mozilla/sops/releases)

For Windows, you cloud install sops separate to mange secrets. This plugin doesn't support Windows yet. See: https://github.com/jkroepke/helm-secrets/issues/7

If you want to skip the automatic sops installation, you have to define `SKIP_SOPS_INSTALL=true` on the `helm plugin install` command.

### Vault

If you use vault with helm-secret, the vault CLI is needed.

You can always install manually in MacOS as below:

```bash
brew install vault
```

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
helm plugin install https://github.com/jkroepke/helm-secrets --version v4.0.0

# Install latest unstable version from master branch
helm plugin install https://github.com/jkroepke/helm-secrets
```

Find the latest version here: https://github.com/jkroepke/helm-secrets/releases

### Manual install

```bash
# MacOS
curl -LsSf https://github.com/jkroepke/helm-secrets/archive/v4.0.0.tar.gz | tar -C "$HOME/Library/helm" -xzf-

# Linux
curl -LsSf https://github.com/jkroepke/helm-secrets/archive/v4.0.0.tar.gz | tar -C "$HOME/.local/share/helm" -xzf-
```

## Change secret driver

It's possible to use an other secret driver then sops, e.g. Hasicorp Vault.

Start by copy the [sops driver](https://github.com/jkroepke/helm-secrets/blob/master/scripts/drivers/sops.sh) and adjust to your own needs.

Custom driver can be load via `SECRET_DRIVER` parameter or `-d` option (higher preference):

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

## Copyright and license

© 2020 [Jan-Otto Kröpke (jkroepke)](https://github.com/jkroepke/helm-secrets)

© 2017-2020 [Zendesk](https://github.com/zendesk/helm-secrets)

Licensed under the [Apache License, Version 2.0](LICENSE)
