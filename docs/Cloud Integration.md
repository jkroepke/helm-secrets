# Cloud Integration

In cloud environments, secrets are stored inside a native secret manager.

This documents describes the vals secrets to dynamically fetch secrets from cloud services directly.

This integration is also supported inside [ArgoCD](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration).

# Prerequisites

- helm-secrets [3.9.x](https://github.com/jkroepke/helm-secrets/releases/tag/v3.9.1) or higher. (literal values requires 4.1+)
- [vals](https://github.com/variantdev/vals) backend usage

## Setup

[vals](https://github.com/variantdev/vals) needs to be setup correctly first.
Download vals and put the binary into your `PATH` environment variable.
Alternatively, use the environment variable `HELM_SECRETS_VALS_PATH` to define the path of the vals binary.

# Authentication

## AWS

AWS supports a multiple mechanism for authentication:

1. Define `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
2. OIDC login flows / IAM Roles for services accounts
3. Default credential and config profiles in `~/.aws/credentials` and `~/.aws/config`
4. Instance profile credentials

## Azure

Azure supports a multiple mechanism for authentication through environment variables

1. **Client Credentials**: Azure AD Application ID and Secret.

    - `AZURE_TENANT_ID`: Specifies the Tenant to which to authenticate.
    - `AZURE_CLIENT_ID`: Specifies the app client ID to use.
    - `AZURE_CLIENT_SECRET`: Specifies the app secret to use.

2. **Client Certificate**: Azure AD Application ID and X.509 Certificate.

    - `AZURE_TENANT_ID`: Specifies the Tenant to which to authenticate.
    - `AZURE_CLIENT_ID`: Specifies the app client ID to use.
    - `AZURE_CERTIFICATE_PATH`: Specifies the certificate Path to use.
    - `AZURE_CERTIFICATE_PASSWORD`: Specifies the certificate password to use.

3. **Resource Owner Password**: Azure AD User and Password. This grant type is *not
   recommended*, use device login instead if you need interactive login.

    - `AZURE_TENANT_ID`: Specifies the Tenant to which to authenticate.
    - `AZURE_CLIENT_ID`: Specifies the app client ID to use.
    - `AZURE_USERNAME`: Specifies the username to use.
    - `AZURE_PASSWORD`: Specifies the password to use.

4. **Azure Managed Service Identity**: Delegate credential management to the platform.
   Requires that code is running in Azure, e.g. on a VM.
   Azure SDK handles all configurations.
   See [Azure Managed Service Identity](https://docs.microsoft.com/azure/active-directory/msi-overview)
   for more details.

# Usage

Before running `helm`, the environment variable `HELM_SECRETS_BACKEND=vals` needs
to be set or the command line option `--backend=vals` must be put in use.

This enables the `vals` integration in helm-secrets.

Vals needs cloud prover credentials to fetch secrets from the secret services.
Be sure to have them in place before trying to use (for instance, use the cloud
provider own CLI to fetch the same secrets).

helm-secrets can not fill the cloud provider secrets store through the encryption command.

> :warning: Vals reference strings must be declared in the "values" file (the
> YAML file being used by the Helm template to provide values), not in the
> resource itself!

This is how you are suppose to do. First create a `Secret` (or anyother
resource you want) file, that we will call `secret.yaml` in this example:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: '{{ .Chart.Name }}-secrets'
  labels:
    app.kubernetes.io/name: '{{ .Chart.Name }}-secrets'
    app.kubernetes.io/version: '{{ .Chart.AppVersion | toString }}'
    namespace: '{{ .Values.namespace }}'
    name: '{{ .Chart.Name }}'
    repository: '{{ .Chart.Home }}'
type: Opaque
data:
  '{{ .Values.secrets.keys.username }}': '{{ .Values.dbUsername | b64enc }}'
  '{{ .Values.secrets.keys.password }}': '{{ .Values.dbPassword | b64enc }}'
```

Then we move this file to a subdirectory, `chart` in this example:

```
mkdir chart
mv secret.yaml chart
```

And then the "values" file, let's call it `values.yaml` and add the following
content:

```yaml
aws: ref+awssecrets://mysecret/value
```

Finally, put everything together:

```
helm secrets template -f values.yaml chart/secret.yaml
```

That's it! You should see some message form `vals` stating that the secrets
were retrieve and the resulting content from the template in the `STDOUT`.

## Supported Backends

`vals` support different backends. Click on the backend to gain more information.

- [Vault](https://github.com/variantdev/vals/blob/main/README.md#vault)
- [AWS SSM Parameter Store](https://github.com/variantdev/vals/blob/main/README.md#aws-ssm-parameter-store)
- [AWS Secrets Manager](https://github.com/variantdev/vals/blob/main/README.md#aws-secrets-manager)
- [AWS S3](https://github.com/variantdev/vals/blob/main/README.md#aws-s3)
- [GCP Secrets Manager](https://github.com/variantdev/vals/blob/main/README.md#gcp-secrets-manager)
- [Google GCS](https://github.com/variantdev/vals/blob/main/README.md#google-gcs)
- [SOPS](https://github.com/variantdev/vals/blob/main/README.md#sops) powered by [sops](https://github.com/mozilla/sops)
- [Terraform (tfstate)](https://github.com/variantdev/vals/blob/main/README.md#terraform-tfstate) powered by [tfstate-lookup](https://github.com/fujiwara/tfstate-lookup)
- [Echo](https://github.com/variantdev/vals/blob/main/README.md#echo)
- [File](https://github.com/variantdev/vals/blob/main/README.md#file)
- [Azure Key Vault](https://github.com/variantdev/vals/blob/main/README.md#azure-key-vault)
- [EnvSubst](https://github.com/variantdev/vals/blob/main/README.md#envsubst)


# Example secret.yaml

```yaml
vault: ref+vault://mykv/foo#/bar
aws: ref+awssecrets://mysecret/value
aws-ssm: ref+awsssm://foo/bar?mode=singleparam#/BAR
gcp: ref+gcpsecrets://PROJECT/SECRET[?version=VERSION]
azure: ref+azurekeyvault://my-vault/secret-a
sops: ref+sops://assets/values/vals/secrets.sops.yaml#/key
file: ref+file:///absolute/path/to/file[#/path/to/the/value]
service:
  port: ref+envsubst://$VAR1
```

# Example literal values

```bash
export HELM_SECRETS_BACKEND=vals
helm secrets template bitnami/mysql --name-template mysql \
  --set auth.rootPassword=ref+awsssm://foo/bar?mode=singleparam#/BAR
```

wrapper-less environment like ArgoCD through downloader syntax (`--set-file` only):

```bash
export HELM_SECRETS_BACKEND=vals
helm template bitnami/mysql --name-template mysql \
  --set-file auth.rootPassword=secrets://ref+azurekeyvault://my-vault/secret-a
```
