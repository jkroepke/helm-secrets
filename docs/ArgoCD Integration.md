# Argo CD Integration

Before starting to integrate helm-secrets with ArgoCD, consider using [age](https://github.com/FiloSottile/age/) over gpg.
[It's recommended to use age encryption over GPG, if possible.](https://github.com/getsops/sops#encrypting-using-age)

Since ArgoCD is a shared environment,
consider reading [Security in shared environments](https://github.com/jkroepke/helm-secrets/wiki/Security-in-shared-environments)
to prevent users from reading files outside the own directory.

➡ With helm-secrets, you can encrypt value files only. Encypted manifests/templates are not supported.

# Prerequisites

- ArgoCD 2.3.0+, 2.2.6+, 2.1.11+ (ArgoCD 2.1.9, 2.1.10, 2.2.4, 2.2.5 is [NOT compatible with helm-secrets](https://github.com/argoproj/argo-cd/issues/8397))
- Multi-source applications requires at least helm-secrets [4.4.0](https://github.com/jkroepke/helm-secrets/releases/tag/v4.4.0) and some special [instructions](#multi-source-application-support-beta)!
- helm-secrets [3.9.x](https://github.com/jkroepke/helm-secrets/releases/tag/v3.9.1) or higher.
- age encrypted values requires at least [3.10.0](https://github.com/jkroepke/helm-secrets/releases/tag/v3.10.0) and sops [3.7.0](https://github.com/getsops/sops/releases/tag/v3.7.0)

# Usage

An Argo CD Application can use the downloader plugin syntax to use encrypted value files.
There are three methods how to use an encrypted value file.
- Method 1: Mount the private key from a kubernetes secret as volume
- Method 2: Fetch the private key directly from a kubernetes secret
- Method 3: Using cloud provider (GCP KMS is used here)

Please refer to the configuration section of the corresponding method for further instructions.

<details>
<summary>Example Application</summary>
<p>

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:
        # Method 1: Mount the gpg/age key from a kubernetes secret as volume
        # secrets+gpg-import://<key-volume-mount>/<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
        # secrets+age-import://<key-volume-mount>/<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
        # Example Method 1: (Assumptions: key-volume-mount=/helm-secrets-private-keys, key-name=app, secrets.yaml is in the root folder)
        - secrets+gpg-import:///helm-secrets-private-keys/key.asc?secrets.yaml

        # ### Method 2: Fetch the gpg/age key from kubernetes secret
        # secrets+gpg-import-kubernetes://<namespace>/<secret-name>#<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
        # secrets+age-import-kubernetes://<namespace>/<secret-name>#<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
        # Example Method 2: (Assumptions: namespace=argocd, secret-name=helm-secrets-private-keys, key-name=app, secret.yaml is in the root folder)
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?secrets.yaml

        # ### Method 3: Use HELM_SECRETS_LOAD_GPG_KEYS
        # Example Method 3: (Assumptions: Pre-seeded gpg agent is running or kube service account has permission to decrypt using kms key, secrets.yaml is in the root folder)
        - secrets://secrets.yaml

      # fileParameters (--set-file) are supported, too.
      fileParameters:
        - name: config
          path: secrets://secrets.yaml
        # requires vals backend
        - name: mysql.rootPassword
          path: secrets+literal://vals!ref+vault://secret/mysql#/rootPassword
```
</p>
</details>

Helm will call helm-secrets
because it is [registered](https://github.com/jkroepke/helm-secrets/blob/4e61c556655b99e16d2faff5fd2312251ad06456/plugin.yaml#L12-L19) as [downloader plugin](https://helm.sh/docs/topics/plugins/#downloader-plugins).

## Multi-Source Application Support [BETA]

ArgoCD has limited supported for helm-secrets and Multi-Source application.

References:
* https://github.com/argoproj/argo-cd/issues/11866
* https://github.com/argoproj/argo-cd/pull/11966

On ArgoCD 2.6.x, helm-secrets isn't supported in Multi-Source application, because the source reference, e.g.: `$ref` needs to be at the beginn of a string.
This is in conflict with helm-secrets, since the string needs to beginn with `secrets://`. On top, ArgoCD do not resolve references in URLs.

`HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH` must be set to `true`, since ArgoCD pass value files with absolute file path.

Ensure that the env `HELM_SECRETS_WRAPPER_ENABLED=true` (default `false`) and
`HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=true` is set on the argocd-repo-server.
Please ensure you are following the lastest installation instructions (updated on 2023-03-03).

### sops backend

If you are using `sops` backend, you have to [mounte](#method-1--mount-the-private-key-from-a-kubernetes-secret-as-volume-on-the-argocd-repo-server)
the gpg keys on the `argocd-repo-server` and additionally define the environment variable `HELM_SECRETS_LOAD_GPG_KEYS` with the path of gpg key as values.
Read more about mounting gpg keys [here](#method-1--mount-the-private-key-from-a-kubernetes-secret-as-volume-on-the-argocd-repo-server)


**Note**: The limitation lives on ArgoCD side. helm-secrets is not able to mitigate the limitations at all.


<details>
<summary>Example Multi-Source Application</summary>
<p>

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  sources:
    - repoURL: 'https://prometheus-community.github.io/helm-charts'
      chart: prometheus
      targetRevision: 15.7.1
      helm:
        valueFiles:
          # Omit any secrets:// prefix, since its not supported in multi source apps
          - $values/charts/prometheus/secrets.yaml

        # inline secret references are still supported
        fileParameters:
          - name: mysql.rootPassword
            path: secrets+literal://vals!ref+awssecrets://myteam/mydoc#/foo/bar
    - repoURL: 'https://git.example.gom/org/value-files.git'
      targetRevision: dev
      ref: values
```
</p>
</details>

# Installation on Argo CD

Before using helm secrets, we are required to install `helm-secrets` on the `argocd-repo-server`.
Depends on the secret backend, `sops` or `vals` is required on the `argocd-repo-server`, too.
There are two methods to do this.
Either create your custom ArgoCD Docker Image or install them via an init container.

## Step 1: Customize argocd-repo-server

### Option 1: Custom Docker Image
Integrating `helm-secrets` with Argo CD can be achieved by building a custom Argo CD Server image.

Only `argocd-repo-server` needs this customized image. Other ArgoCD components can use the customized or upstream variant.

Below is an example `Dockerfile` which incorporates `sops` and `helm-secrets` into the Argo CD image:

<details>
<summary>Dockerfile</summary>
<p>

```Dockerfile
ARG ARGOCD_VERSION="v2.6.2"
FROM argoproj/argocd:$ARGOCD_VERSION
ARG SOPS_VERSION="3.8.1"
ARG VALS_VERSION="0.37.1"
ARG HELM_SECRETS_VERSION="4.6.0"
ARG KUBECTL_VERSION="1.30.1"
# vals or sops
ENV HELM_SECRETS_BACKEND="vals" \
    HELM_SECRETS_HELM_PATH=/usr/local/bin/helm \
    HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/" \
    HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false \
    HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false \
    HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false \
    HELM_SECRETS_WRAPPER_ENABLED=false

# Optionally, set default gpg key for sops files
# ENV HELM_SECRETS_LOAD_GPG_KEYS=/path/to/gpg.key

USER root
RUN apt-get update && \
    apt-get install -y \
      curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -fsSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# sops backend installation (optional)
RUN curl -fsSL https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64 \
    -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops

# vals backend installation (optional)
RUN curl -fsSL https://github.com/helmfile/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_amd64.tar.gz \
    | tar xzf - -C /usr/local/bin/ vals \
    && chmod +x /usr/local/bin/vals

RUN ln -sf "$(helm env HELM_PLUGINS)/helm-secrets/scripts/wrapper/helm.sh" /usr/local/sbin/helm

USER argocd

RUN helm plugin install --version ${HELM_SECRETS_VERSION} https://github.com/jkroepke/helm-secrets
```

</details>

Make sure to specify your custom image when deploying Argo CD.

### Option 2: Init Container

Install sops or vals and helm-secret through an init container on the `argocd-repo-server` Deployment.

This is an example values file for the [ArgoCD Server Helm chart](https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd).

<details>
<summary>values.yaml</summary>
<p>

```yaml
repoServer:
  env:
    - name: HELM_PLUGINS
      value: /custom-tools/helm-plugins/
    - name: HELM_SECRETS_CURL_PATH
      value: /custom-tools/curl
    - name: HELM_SECRETS_SOPS_PATH
      value: /custom-tools/sops
    - name: HELM_SECRETS_VALS_PATH
      value: /custom-tools/vals
    - name: HELM_SECRETS_KUBECTL_PATH
      value: /custom-tools/kubectl
    - name: HELM_SECRETS_BACKEND
      value: sops
    # https://github.com/jkroepke/helm-secrets/wiki/Security-in-shared-environments
    - name: HELM_SECRETS_VALUES_ALLOW_SYMLINKS
      value: "false"
    - name: HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH
      value: "true"
    - name: HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL
      value: "false"
    - name: HELM_SECRETS_WRAPPER_ENABLED
      value: "true"
    - name: HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR
      value: "true"
    - name: HELM_SECRETS_HELM_PATH
      value: /usr/local/bin/helm

    - name: HELM_SECRETS_LOAD_GPG_KEYS
      # Multiple keys can be separated by space
      value: /helm-secrets-private-keys/key.asc
  volumes:
    - name: custom-tools
      emptyDir: {}
    # kubectl create secret generic helm-secrets-private-keys --from-file=key.asc=assets/gpg/private2.gpg
    - name: helm-secrets-private-keys
      secret:
        secretName: helm-secrets-private-keys
  volumeMounts:
    - mountPath: /custom-tools
      name: custom-tools
    - mountPath: /usr/local/sbin/helm
      subPath: helm
      name: custom-tools
    - mountPath: /helm-secrets-private-keys/
      name: helm-secrets-private-keys
  initContainers:
    - name: download-tools
      image: alpine:latest
      imagePullPolicy: IfNotPresent
      command: [sh, -ec]
      env:
        - name: HELM_SECRETS_VERSION
          value: "4.6.0"
        - name: KUBECTL_VERSION
          value: "1.30.1"
        - name: VALS_VERSION
          value: "0.37.1"
        - name: SOPS_VERSION
          value: "3.8.1"
      args:
        - |
          mkdir -p /custom-tools/helm-plugins
          wget -qO- https://github.com/jkroepke/helm-secrets/releases/download/v${HELM_SECRETS_VERSION}/helm-secrets.tar.gz | tar -C /custom-tools/helm-plugins -xzf-;

          wget -qO /custom-tools/curl https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64
          wget -qO /custom-tools/sops https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64
          wget -qO /custom-tools/kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

          wget -qO- https://github.com/helmfile/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_amd64.tar.gz | tar -xzf- -C /custom-tools/ vals;

          cp /custom-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /custom-tools/helm

          chmod +x /custom-tools/*
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
```

</details>

Instead, downloading all external files on container start, consider building an own docker image which contains all required binaries. See [Dockerfile](https://github.com/jkroepke/helm-secrets/blob/main/Dockerfile) in repository root.

## Step 2: Allow helm-secrets schemes in argocd-cm ConfigMap

By default, ArgoCD only allows `http://` and `https://` as remote value schemes.

The helm-secrets schemes need to be added to the [argocd-cm ConfigMap](https://github.com/argoproj/argo-cd/blob/af5f234bdbc8fd9d6dcc90d12e462316d9af32cf/docs/operator-manual/argocd-cm.yaml#L225-L227):

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
data:
  helm.valuesFileSchemes: >-
    secrets+gpg-import, secrets+gpg-import-kubernetes,
    secrets+age-import, secrets+age-import-kubernetes,
    secrets,secrets+literal,
    https
```

The [ArgoCD Server Helm chart](https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd) supports defining `argocd-cm` settings through [values.yaml](https://github.com/argoproj/argo-helm/blob/6ff050f6f57edda1e6912ef0bb17d085684e103e/charts/argo-cd/values.yaml#L1155-L1157):

```yaml
server:
  config:
    helm.valuesFileSchemes: >-
      secrets+gpg-import, secrets+gpg-import-kubernetes,
      secrets+age-import, secrets+age-import-kubernetes,
      secrets,secrets+literal,
      https
```

# Configuration of ArgoCD

When using private key encryption, it is required to configure ArgoCD repo server so that it has access
to the private key to decrypt the encrypted value file(s). When using GCP KMS, encrypted value file(s)
can be decrypted using [Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials).

## Private key encryption (sops backend only)
There are two ways to configure ArgoCD to have access to your private key:

- mount the PGP/age key secret as a volume in the argocd-repo-server; or
- fetch the secret value (private key) directly using Kubernetes API.

Both methods depend on a Kubernetes secret holding the key in plain-text format (i.e., not encrypted or protected by a passphrase).

### Generating the key
#### Using GPG
```bash
gpg --full-generate-key --rfc4880
```

When asked to enter a password, you need to omit it.

Please also note that currently it is recommended to use the --rfc4880.
This prevents you from running into a compatibility issue between gpg 2.2 and gpg 2.3
(Related Issue: [Encryption with GnuPG 2.3 (RFC4880bis) causes compatibility issues with GnuPG 2.2](https://github.com/getsops/sops/issues/896))

```bash
gpg --armor --export-secret-keys <key-id> > key.asc
```
The key-id can be found in the output of the generate-key command.
It looks something like this:
```
gpg: key 1234567890987654321 marked as ultimately trusted
```

#### Using age
```bash
age-keygen -o key.txt
```

The public key can be found in the output of the generate-key command.
Unlike gpg, age does not have an agent. [To encrypt the key with sops](https://github.com/getsops/sops#encrypting-using-age), set the environment variables

* `SOPS_AGE_KEY_FILE="path/age/key.txt"`
* `SOPS_AGE_RECIPIENTS=public-key`

before running sops. Defining `SOPS_AGE_RECIPIENTS` is only required on initial encryption of a plain file.

### Creating the kubernetes secret holding the exported private key
#### Using GPG
```bash
kubectl -n argocd create secret generic helm-secrets-private-keys --from-file=key.asc=assets/gpg/private2.gpg
```

#### Using age
```bash
kubectl -n argocd create secret generic helm-secrets-private-keys --from-file=key.txt=assets/age/key.txt
```

### Making the key accessible within ArgoCD
#### Method 1: Mount the private key from a kubernetes secret as volume on the argocd-repo-server

To use the *secrets+gpg-import / secrets+age-import* syntax, the keys need to be mounted on the **argocd-repo-server**.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).
```yaml
repoServer:
  env:
    - name: HELM_SECRETS_LOAD_GPG_KEYS # For GPG
      # Multiple keys can be separated by space
      value: /helm-secrets-private-keys/key.asc
    - name: SOPS_AGE_KEY_FILE # For age
      value: /helm-secrets-private-keys/key.txt
  volumes:
    - name: helm-secrets-private-keys
      secret:
        secretName: helm-secrets-private-keys
  volumeMounts:
    - mountPath: /helm-secrets-private-keys/
      name: helm-secrets-private-keys
```

Once mounted, your Argo CD Application should look similar to this:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:
        # Method 1: Use gpg key defined in HELM_SECRETS_LOAD_GPG_KEYS or age key defined in SOPS_AGE_KEY_FILE
        - secrets://secrets.yaml

        # Method 2: Dynamically reference the gpg key inside values file
        # secrets+gpg-import://<key-volume-mount>/<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
        # secrets+age-import://<key-volume-mount>/<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
        # Example Method 2: (Assumptions: key-volume-mount=/helm-secrets-private-keys, key-name=app, secret.yaml is in the root folder)
        - secrets+gpg-import:///helm-secrets-private-keys/key.asc?secrets.yaml
```


#### Method 2: Fetch the gpg key directly from a kubernetes secret

To use the *secrets+gpg-import-kubernetes / secrets+age-import-kubernetes* syntax, we need Argo CD's service account to be able to access the secret.
To achieve this, we use the RBAC Permissions.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).
```yaml
# This allows reading secrets in the same namespace
repoServer:
  serviceAccount:
    create: true
    name: argocd-repo-server

  rbac:
    - apiGroups:
        - ""
      resources:
        - secrets
      verbs:
        - get
```

RBAC permissions can be verified by executing the command below:

```bash
export NAMESPACE=argo-cd
kubectl auth can-i get secrets --namespace "${NAMESPACE}" --as "system:serviceaccount:${NAMESPACE}:argocd-repo-server"
```

Once granted access, your Argo CD Application should look similar to this:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:

        # ### Method 2: Fetch the gpg key from kubernetes secret
        # secrets+gpg-import-kubernetes://<namespace>/<secret-name>#<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
        # secrets+age-import-kubernetes://<namespace>/<secret-name>#<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
        # Example Method 2: (Assumptions: namespace=argocd, secret-name=helm-secrets-private-keys, key-name=app, secret.yaml is in the root folder)
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?secrets.yaml
```

## External key location

sops and vals are supporting multiple cloud providers.

### AWS

The argocd-repo-server need access to cloud services. If ArgoCD is deployed on an EKS,
[AWS IRSA](https://docs.aws.amazon.com/eks/latest/userguide/specify-service-account-role.html) can be used here.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm):
```yaml
repoServer:
  serviceAccount:
    create: true
    name: "argocd-repo-server"
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/iam-role-name
    automountServiceAccountToken: true
```

If IRSA is not available, move forward with static credentials.

1. Create a secret contain the `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
   Example:
   ```bash
   kubectl create secret generic argocd-aws-credentials \
     --from-literal=AWS_DEFAULT_REGION=eu-central-1 \
     --from-literal=AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
     --from-literal=AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

2. Configure the secrets inside ArgoCD Helm Chart:
   Example:
   ```yaml
   repoServer:
     envFrom:
     - secretRef:
         name: argocd-aws-credentials
   ```

### GCP KMS

To work with GCP KMS encrypted value files, no private keys need to be provided to ArgoCD,
but the Kubernetes ServiceAccount which runs the argocd-repo-server needs to have the `cloudkms.cryptoKeyVersions.useToDecrypt` permission.
There are various ways to achieve this,
but the recommended way is to use [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).
Please read Google's documentation to link your Kubernetes ServiceAccount and a Google Service Account.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm):
```yaml
repoServer:
  serviceAccount:
    create: true
    name: "argocd-repo-server"
    annotations:
      iam.gke.io/gcp-service-account: YOUR_GOOGLE_SERVICE_ACCOUNT_EMAIL_ID
    automountServiceAccountToken: true
```

To ensure your Google Service Account has the right permission, the easiest way is to grant it the role `roles/cloudkms.cryptoKeyDecrypter`.

Once granted access, your Argo CD Application should look similar to this:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:
        # ### Method 3: No keys provided
        # Example Method 3: (Assumptions: kube service account has permission to decrypt using kms key, secrets.yaml is in the root folder)
        - secrets://secrets.yaml
```

# Known Limitations
## External Chart and local values
Please take a look at [this issue](https://github.com/argoproj/argo-cd/issues/7257) for more information.

As workaround, you can fetch additional values from remote locations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:
        # if AWS KMS or GCP is used
        - secrets://https://raw.githubusercontent.com/org/repo/ref/pathtofile.yml
        # if gpg or age encrypted is used.
        - secrets+gpg-import:///helm-secrets-private-keys/key.asc?https://raw.githubusercontent.com/org/repo/ref/pathtofile.yml
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?https://raw.githubusercontent.com/org/repo/ref/pathtofile.yml
        # if HELM_SECRETS_URL_VARIABLE_EXPANSION is set to true, GITHUB_TOKEN needs to be set as environment variables else where, e.g. at the deployment spec
        - secrets://https://$${GITHUB_TOKEN}@raw.githubusercontent.com/org/repo/ref/pathtofile.yml
        # Using https://github.com/aslafy-z/helm-git
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?git+https://github.com/jkroepke/helm-secrets@tests/assets/values/sops/secrets.yaml?ref=main"
```

See https://github.com/jkroepke/helm-secrets/wiki/Values for more information about remote value files.
