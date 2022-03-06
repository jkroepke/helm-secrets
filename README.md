[![CI](https://github.com/jkroepke/helm-secrets/workflows/CI/badge.svg)](https://github.com/jkroepke/helm-secrets/)
[![License](https://img.shields.io/github/license/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/blob/main/LICENSE)
[![Current Release](https://img.shields.io/github/release/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/jkroepke/helm-secrets/total?logo=github)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/pulls)
[![codecov](https://codecov.io/gh/jkroepke/helm-secrets/branch/main/graph/badge.svg?token=4qAukyB2yX)](https://codecov.io/gh/jkroepke/helm-secrets)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/secrets)](https://artifacthub.io/packages/helm-plugin/secrets/secrets)

# helm-secrets

## Installation

See [Installation](https://github.com/jkroepke/helm-secrets/wiki/Installation) for more information.

## Usage

### Decrypt secrets via protocol handler

Run decrypted command on specific value files. This is method is preferred over the plugin command below.

```bash
helm upgrade name . -f secrets://secrets.yaml
```

See [Usage](https://github.com/jkroepke/helm-secrets/wiki/Usage) for more information

### Decrypt secrets via plugin command

Wraps the whole helm command. Slow on multiple value files.

```bash
helm secrets upgrade name . -f secrets.yaml
```

## ArgoCD support

For running helm-secrets with ArgoCD, see [ArgoCD Integration](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration) for more information.

## Terraform support

The Terraform helm provider does not [support downloader plugins](https://github.com/hashicorp/terraform-provider-helm).

helm secrets can be used together with the [terraform external data source provider](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source).

```hcl
data "external" "helm-secrets" {
  program = ["helm", "secrets", "terraform", "../../examples/sops/secrets.yaml"]
}

resource "helm_release" "example" {
  ...

  values = [
    file("../../examples/sops/values.yaml"),
    base64decode(data.external.helm-secrets.result.content_base64),
  ]
}
```
An example how to use helm-secrets with terraform could be found in [examples/terraform](examples/terraform/helm.tf).

## Secret drivers

helm-secrets supports multiplie secret drivers like [sops](https://github.com/mozilla/sops), [Hasicorp Vault](https://www.vaultproject.io/), [vals](https://github.com/variantdev/vals/) and more.

See [Secret-Driver](https://github.com/jkroepke/helm-secrets/wiki/Secret-Driver) how to use them.

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

An additional documentation, resources and examples can be found [here](https://github.com/jkroepke/helm-secrets/wiki/Usage).

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
