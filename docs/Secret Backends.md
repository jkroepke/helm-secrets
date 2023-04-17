# Secret Backends

helm-secret support multiple backend. [sops](https://github.com/mozilla/sops) and [vals](https://github.com/variantdev/vals).
sops is good for on-premise installation. vals can be used to fetch secrets from external systems like AWS Secrets Manager or Azure KeyVault. 

Example for in-tree backends via an CLI option
```bash
helm secrets -b sops decrypt ./tests/assets/helm_vars/secrets.yaml
```

Example for in-tree backends via environment variable
```bash
HELM_SECRETS_BACKEND=vals helm secrets decrypt ./tests/assets/helm_vars/secrets.yaml
```

Example for out-of-tree backends
```bash
helm secrets -b ./path/to/backend.sh decrypt ./tests/assets/helm_vars/secrets.yaml
```

The backend option is a global one. A file level switch is supported, too.

```bash
helm secrets template . -f 'sops!tests/assets/helm_vars/secrets.yaml'
```

For more information, read [USAGE.md](./Usage.md#override-backend-per-value-file)

## Implement an own secret backend

Start by a copy of [sops backend](https://github.com/jkroepke/helm-secrets/blob/main/scripts/backends/sops.sh) and adjust to your own needs.
The custom backend can be load via `HELM_SECRETS_BACKEND` parameter or `-d` option (higher preference).

## Pass additional arguments to a secret backend

```bash
helm secrets -a "--verbose" decrypt ./tests/assets/helm_vars/secrets.yaml
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

## Explicitly specify a binary path

If e.g. `sops` is installed at the non-default location or if you have multiple versions of sops on your system, 
you can use `HELM_SECRETS_$BACKEND_PATH` to explicitly specify the sops binary to be used.

```bash
# Example for in-tree backends via environment variable
HELM_SECRETS_SOPS_PATH=/custom/location/sops helm secrets decrypt ./tests/assets/helm_vars/secrets.yaml
HELM_SECRETS_VALS_PATH=/custom/location/vals helm secrets decrypt ./tests/assets/helm_vars/secrets.yaml
```

# List of implemented secret backends

## sops

If you use sops with helm-secrets, the sops CLI tool is needed. 
sops 3.2.0 is required at a minimum.

Download: https://github.com/mozilla/sops/releases/latest

Before starting using sops with gpg, consider starting to use [age](https://github.com/mozilla/sops#encrypting-using-age).

The sops secret store is enabled by default.

## vals

[vals](https://github.com/variantdev/vals) is a tool for managing configuration values and secrets form various sources.

To use vals with helm-secrets, the vals CLI binary is needed. vals 0.22.0 or higher is required.

It supports various backends:

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

The vals secret backend can be enabled by define `HELM_SECRETS_BACKEND=vals`.

Example file: [examples/vals/secrets.yaml](https://github.com/jkroepke/helm-secrets/blob/main/examples/vals/secrets.yaml)
