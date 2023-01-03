[![CI](https://github.com/jkroepke/helm-secrets/workflows/CI/badge.svg)](https://github.com/jkroepke/helm-secrets/)
[![License](https://img.shields.io/github/license/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/blob/main/LICENSE)
[![Current Release](https://img.shields.io/github/release/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/jkroepke/helm-secrets/total?logo=github)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/pulls)
[![codecov](https://codecov.io/gh/jkroepke/helm-secrets/branch/main/graph/badge.svg?token=4qAukyB2yX)](https://codecov.io/gh/jkroepke/helm-secrets)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/secrets)](https://artifacthub.io/packages/helm-plugin/secrets/secrets)

# helm-secrets

## About

helm-secrets is a Helm plugin for decrypt encrypted Helm **value files** on the fly.

* Use [sops](https://github.com/mozilla/sops) to encrypt value files and store them into git.
* Store your secrets a cloud native secret manager like AWS SecretManager, Azure KeyVault or HashiCorp Vault and inject them inside value files or templates.
* Use helm-secret in your favorite deployment tool or GitOps Operator like ArgoCD

Who’s actually using helm-secrets? If you are using helm-secrets in your company or organization, we would like to invite you to create a PR to add your
information to this [file](./USERS.md).

## Installation

See [Installation](https://github.com/jkroepke/helm-secrets/wiki/Installation) for more information.

## Usage

For full documentation, read [GitHub wiki](https://github.com/jkroepke/helm-secrets/wiki/Usage).

### Decrypt secrets via protocol handler

Run decrypted command on specific value files. 
This is method is preferred over the plugin command below. 
This mode is used in [ArgoCD](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration) environments.

On Windows, the command `helm secrets patch windows` needs to be run first.

```bash
helm upgrade name . -f secrets://secrets.yaml
```

See [Usage](https://github.com/jkroepke/helm-secrets/wiki/Usage) for more information

### Decrypt secrets via plugin command

Wraps the whole  `helm` command. Slow on multiple value files.

```bash
helm secrets upgrade name . -f secrets.yaml
```


### Evaluate secret reference inside helm template

*requires helm 3.9+*

helm-secrets supports evaluating [vals](https://github.com/variantdev/vals) expressions inside Helm templates by
enable the flag `--evaluate-templates`.

**secrets.yaml**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret
type: Opaque
stringData:
  password: "ref+awsssm://foo/bar?mode=singleparam#/BAR"
```

**Run**
```bash
helm secrets --evaluate-templates upgrade name .
```

## Cloud support

Use AWS Secrets Manager or Azure KeyVault for storing secrets securely and reference them inside values.yaml

```bash
helm secrets --backend vals template bitnami/mysql --name-template mysql \
  --set auth.rootPassword=ref+awsssm://foo/bar?mode=singleparam#/BAR
```

See [Cloud Integration](https://github.com/jkroepke/helm-secrets/wiki/Cloud-Integration) for more information.


## ArgoCD support

For running helm-secrets with ArgoCD, see [ArgoCD Integration](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration) for more information.

### Example

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:
        - secrets+gpg-import:///helm-secrets-private-keys/key.asc?secrets.yaml
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?secrets.yaml
        - secrets://secrets.yaml
      # fileParameters (--set-file) are supported, too. 
      fileParameters:
        - name: config
          path: secrets://secrets.yaml
        # directly reference values from Cloud Providers
        - name: mysql.rootPassword
          path: secrets+literal://ref+azurekeyvault://my-vault/secret-a
```

## Terraform support

The Terraform Helm provider does not [support downloader plugins](https://github.com/hashicorp/terraform-provider-helm).

helm-secrets can be used together with the [Terraform external data source provider](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source).

### Example

```hcl
data "external" "helm-secrets" {
  program = ["helm", "secrets", "decrypt", "--terraform", "../../examples/sops/secrets.yaml"]
}

resource "helm_release" "example" {
  

  values = [
    file("../../examples/sops/values.yaml"),
    base64decode(data.external.helm-secrets.result.content_base64),
  ]
}
```

An example of how to use helm-secrets with Terraform could be found in [examples/terraform](examples/terraform/helm.tf).

## Secret backends

helm-secrets support multiple secret backends.
Currently, [sops](https://github.com/mozilla/sops) and [vals](https://github.com/variantdev/vals/) are supported.

See [Secret-Backends](https://github.com/jkroepke/helm-secrets/wiki/Secret-Backends) how to use them.

## Documentation

An additional documentation, resources and examples can be found [here](https://github.com/jkroepke/helm-secrets/wiki/Usage).

## Moving parts of project

- [`scripts/run.sh`](scripts/run.sh) - Main helm-secrets plugin code for all helm-secrets plugin actions available in `helm secrets help` after plugin install
- [`scripts/backends`](scripts/backends) - Location of the in-tree secrets backends
- [`scripts/commands`](scripts/commands) - Sub Commands of `helm secrets` are defined here.
- [`scripts/lib`](scripts/lib) - Common functions used by `helm secrets`.
- [`scripts/wrapper`](scripts/wrapper) - Wrapper scripts for Windows systems.
- [`tests`](tests) - Test scripts to check if all parts of the plugin work. Using test assets with PGP keys to make real tests on real data with real encryption/decryption. See [`tests/README.md`](tests/README.md) for more informations.
- [`examples`](examples) - Some example secrets.yaml

## Copyright and license

© 2020-2022 [Jan-Otto Kröpke (jkroepke)](https://github.com/jkroepke/helm-secrets)

© 2017-2020 [Zendesk](https://github.com/zendesk/helm-secrets)

Licensed under the [Apache License, Version 2.0](LICENSE)
