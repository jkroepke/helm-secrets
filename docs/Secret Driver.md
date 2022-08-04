# Secret Driver

It's possible to use another secret driver then sops, e.g. Hasicorp Vault.

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

The driver option is a global one. A file level switch isn't supported yet.

## Implement an own secret driver

Start by a copy of [sops driver](https://github.com/jkroepke/helm-secrets/blob/main/scripts/drivers/sops.sh) and adjust to your own needs.
The custom driver can be load via `HELM_SECRETS_DRIVER` parameter or `-d` option (higher preference).

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

## Explicitly specify binary path

If e.g. sops is installed at the non-default location or if you have multiple versions of sops on your system, you can use `HELM_SECRETS_$DRIVER_PATH` to explicitly specify the sops binary to be used.

```bash
# Example for in-tree drivers via environment variable
HELM_SECRETS_SOPS_PATH=/custom/location/sops helm secrets view ./tests/assets/helm_vars/secrets.yaml
HELM_SECRETS_VALS_PATH=/custom/location/vals helm secrets view ./tests/assets/helm_vars/secrets.yaml
```

# List of implemented secret drivers

## sops

If you use sops with helm-secrets, the sops CLI tool is needed. 
sops 3.2.0 is required at minimum.

Download: https://github.com/mozilla/sops/releases/latest

Before start to use sops with gpg, consider start to use [age](https://github.com/mozilla/sops#encrypting-using-age).

The sops secret store is enabled by default.

## vals

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

The vals secret driver can be enabled by define `HELM_SECRETS_DRIVER=vals`.

Example file: [examples/vals/secrets.yaml](https://github.com/jkroepke/helm-secrets/blob/main/examples/vals/secrets.yaml)

## Hashicorp Vault

If you use Vault with helm-secrets, the vault CLI tool is needed.

Download: https://www.vaultproject.io/downloads

The vault secret driver can be enabled by define `HELM_SECRETS_DRIVER=vault`.

Example file: [examples/vault/secrets.yaml](https://github.com/jkroepke/helm-secrets/blob/main/examples/vault/secrets.yaml) 

## envsubst

If you have stored you secret inside environment variables, you could use the envsubst driver.

### Installation

#### MacOS

```bash
brew install gettext
```

#### Linux

```bash
apt-get install gettext
```

## Doppler

If you use [Doppler](https://doppler.com) with helm-secrets, the doppler CLI tool is needed.

Installation: https://docs.doppler.com/docs/enclave-installation

You need to make sure chart folder or parent one is in correct CLI's scope with enough access to project.

Example file: [examples/doppler/secrets.yaml](https://github.com/jkroepke/helm-secrets/blob/main/examples/doppler/secrets.yaml) 
