# Argo CD Integration

Before starting to integrate helm-secrets with ArgoCD, consider using [age](https://github.com/FiloSottile/age/) over gpg.
[It's recommended to use age over GPG, if possible.](https://github.com/mozilla/sops#encrypting-using-age)

## Prerequisites

- helm-secrets [3.9.x](https://github.com/jkroepke/helm-secrets/releases/tag/v3.9.1) or higher.
- age encrypted values requires at least [3.10.x](https://github.com/jkroepke/helm-secrets/releases/tag/v3.10.0).

## Usage

An Argo CD Application can use the downloader plugin syntax to use encrypted value files.
There are three methods how to use an encrypted value file.
- Method 1: Mount the private key from a kubernetes secret as volume
- Method 2: Fetch the private key directly from a kubernetes secret
- Method 3: Using GCP KMS (no keys provided)

Please refer to the configuration section of the corresponding method for further instructions.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
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

        # ### Method 3: No keys provided
        # Example Method 3: (Assumptions: kube service account has permission to decrypt using kms key, secrets.yaml is in the root folder)
        - secrets://secrets.yaml
```

Helm will call helm-secrets because helm-secrets is [registered](https://github.com/jkroepke/helm-secrets/blob/4e61c556655b99e16d2faff5fd2312251ad06456/plugin.yaml#L12-L19) as [downloader plugin](https://helm.sh/docs/topics/plugins/#downloader-plugins).

## Installation on Argo CD

Before using helm secrets, we are required to install helm-secrets and sops on the ArgoCD Repo Server.
There are two methods to do this. Either create your custom ArgoCD Docker Image or install them via init container.

### Option 1: Custom Docker Image
Integrating `helm-secrets` with Argo CD can be achieved by building a custom Argo CD Server image.

Below is an example `Dockerfile` which incorporates `sops` and `helm-secrets` into the Argo CD image:
```Dockerfile
ARG ARGOCD_VERSION="v2.1.2"
FROM argoproj/argocd:$ARGOCD_VERSION
ARG SOPS_VERSION="3.7.1"
ARG HELM_SECRETS_VERSION="3.10.0"
ARG KUBECTL_VERSION="1.22.0"

USER root
RUN apt-get update && \
    apt-get install -y \
      curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl -fSSL https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux \
    -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops
RUN curl -fSSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

USER argocd
ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
RUN helm plugin install --version ${HELM_SECRETS_VERSION} https://github.com/jkroepke/helm-secrets
```

Make sure to specify your custom image when deploying Argo CD.

### Option 2: Init Container

install sops or vals and helm-secret through an init container.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).

```yaml
repoServer:
  env:
    - name: HELM_PLUGINS
      value: /custom-tools/helm-plugins/
    - name: HELM_SECRETS_SOPS_PATH
      value: /custom-tools/sops
    - name: HELM_SECRETS_KUBECTL_PATH
      value: /custom-tools/kubectl
  volumes:
    - name: custom-tools
      emptyDir: {}
  volumeMounts:
    - mountPath: /custom-tools
      name: custom-tools

  initContainers:
    - name: download-tools
      image: alpine:latest
      command: [sh, -ec]
      env:
        - name: HELM_SECRETS_VERSION
          value: "3.10.0"
        - name: SOPS_VERSION
          value: "3.7.1"
        - name: KUBECTL_VERSION
          value: "1.22.0"
      args:
        - |
          mkdir -p /custom-tools/helm-plugins
          wget -qO- https://github.com/jkroepke/helm-secrets/releases/download/v${HELM_SECRETS_VERSION}/helm-secrets.tar.gz | tar -C /custom-tools/helm-plugins -xzf-;

          wget -qO /custom-tools/sops https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux
          wget -qO /custom-tools/kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

          chmod +x /custom-tools/*
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
```

## Configuration of ArgoCD

When using private key encryption it is required to configure ArgoCD so that it has access to the private key to decrypt the encrypted value file(s). When using GCP KMS, encrypted value file(s) can be decrypted using [Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials).

### Private key encryption
There are two ways to configure ArgoCD to have access to your private key.
Either mount the gpg key from secret as volume or access the fetch the private key directly from a kubernetes secret.
Both methods depend on a secret holding the key in asci format.

#### Using GPG
##### Generating the key and export it as ASCI File.

```shell
gpg --full-generate-key --rfc4880
```

When asked to enter a password you need to omit it.

Please also note that currently it is recommended to use the --rfc4880.
This prevents you from running into a compatibility issue between gpg 2.2 and gpg 2.3. (Related Issue: [Encryption with GnuPG 2.3 (RFC4880bis) causes compatibility issues with GnuPG 2.2](https://github.com/mozilla/sops/issues/896))

```shell
gpg --armor --export-key <key-id> > key.asc
```
The key-id can be found in the output of the generate-key command.
It looks something like this:
```
gpg: key 1234567890987654321 marked as ultimately trusted
```

#### Using age
##### Generating the key

```shell
age-keygen -o key.txt
```

The public key can be found in the output of the generate-key command.
Unlike gpg, age does not have an agent. [To encrypt the key with sops](https://github.com/mozilla/sops#encrypting-using-age), set the environment variables

* `SOPS_AGE_KEY_FILE="path/age/key.txt"`
* `SOPS_AGE_RECIPIENTS=public-key`

before running sops. Define `SOPS_AGE_RECIPIENTS` is only required on initial encryption of a plain file.

#### Creating the kubernetes secret holding the exported private key
```shell
kubectl create secret generic helm-secrets-private-keys --from-file=key.asc
```

#### Making the key accessible within ArgoCD
##### Method 1: Mount the private key from a kubernetes secret as volume

To use the *secrets+gpg-import / secrets+age-import* syntax, we need to mount the key on the ArgoCD Repo Server.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).
```yaml
repoServer:
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
...
spec:
  source:
    helm:
      valueFiles:
        # Method 1: Mount the gpg key from a kubernetes secret as volume
        # secrets+gpg-import://<key-volume-mount>/<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
        # secrets+age-import://<key-volume-mount>/<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
        # Example Method 1: (Assumptions: key-volume-mount=/helm-secrets-private-keys, key-name=app, secret.yaml is in the root folder)
        - secrets+gpg-import:///helm-secrets-private-keys/key.asc?secrets.yaml
```


#### Method 2: Fetch the gpg key directly from a kubernetes secret

To use the *secrets+gpg-import-kubernetes / secrets+age-import-kubernetes* syntax, we need Argo CD's service account to be able to access the secret.
To achieve this we use the RBAC Permissions.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).
```yaml
# This allows to read secrets in the same namespace
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
    - list
    - watch
```

RBAC permissions can be verified by executing the command below:

```bash
kubectl auth can-i get secrets --namespace argo-cd --as system:serviceaccount:$NAMESPACE:argo-cd-argocd-repo-server
```

Once granted access, your Argo CD Application should look similar to this:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
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

### No private key encryption
#### Method 3: GCP KMS

To work with GCP KMS encrypted value files, no private keys need to be provided to ArgoCD, but the Kubernetes ServiceAccount which runs the argocd-repo-server needs to have the `cloudkms.cryptoKeyVersions.useToDecrypt` permission. There are various ways to achieve this, but the recommended way is to use [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity). Please read Google's documentation to link your Kubernetes ServiceAccount and a Google Service Account.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm):
```
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
...
spec:
  source:
    helm:
      valueFiles:

        # ### Method 3: No keys provided
        # Example Method 3: (Assumptions: kube service account has permission to decrypt using kms key, secrets.yaml is in the root folder)
        - secrets://secrets.yaml
```

## Known Limitations
### External Chart and local values
Please note that it is not possible to use helm secrets in Argo CD for external Charts.
Please take a look at [this issue](https://github.com/argoproj/argo-cd/issues/7257) for more information.

As workaround, you can fetch additional values from remote locations:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
spec:
  source:
    helm:
      valueFiles:
        - secrets+gpg-import:///helm-secrets-private-keys/key.asc?https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/sops/values.yaml
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/sops/values.yaml
        # Using https://github.com/aslafy-z/helm-git
        - secrets+gpg-import-kubernetes://argocd/helm-secrets-private-keys#key.asc?git+https://github.com/jkroepke/helm-secrets@tests/assets/values/sops/secrets.yaml?ref=main"
```

## Known Issues
### Compatibility issue between gpg 2.2 and gpg 2.3.

Error:
```
Error decrypting tree: Error walking tree: Could not decrypt value: crypto/aes: invalid key size 0
```
For possible workarounds see [Issue 1](https://github.com/jkroepke/helm-secrets/issues/158) and [Issue 2](https://github.com/mozilla/sops/issues/896)
