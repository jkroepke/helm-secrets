# Argo CD Integration

_Available since helm-secrets 3.9.0_

When deploying an Argo CD application, encrypted values files can be specified using the downloader plugin syntax:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
spec:
  source:
    helm:
      valueFiles:
        - path/to/values.yaml
        - secrets+gpg-import:///gpg-private-keys/app.asc?path/to/secrets.yaml
        - secrets+gpg-import-kubernetes://argocd/argocd-gpg-key#private.asc?path/to/secrets.yaml
``` 

### External Chart and local values
Please mention, this won't work with external helm charts, subscribe https://github.com/argoproj/argo-cd/issues/7257 for more infos.

As workaround, you can fetch additional values from remote locations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
spec:
  source:
    helm:
      valueFiles:
        - https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/sops/values.yaml
        - secrets+gpg-import:///gpg-private-keys/app.asc?https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/sops/values.yaml
        - secrets+gpg-import-kubernetes://argocd/argocd-gpg-key#private.asc?https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/sops/values.yaml
        # Using https://github.com/aslafy-z/helm-git
        - secrets+gpg-import-kubernetes://argocd/argocd-gpg-key#private.asc?git+https://github.com/jkroepke/helm-secrets@tests/assets/values/sops/secrets.yaml?ref=main"

``` 

## Install helm-secrets and sops

### Method 1: Custom Server Image
Integrating `helm-secrets` with Argo CD can be achieved by building a custom Argo CD server image.

Below is an example `Dockerfile` which incorporates `sops` and `helm-secrets` into the Argo CD image:
```Dockerfile
ARG ARGOCD_VERSION="v2.1.2"
FROM argoproj/argocd:$ARGOCD_VERSION
ARG SOPS_VERSION="3.7.1"
ARG HELM_SECRETS_VERSION="3.9.0"
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

### Method 2: Init Container

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
          value: "3.9.0"
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

## GPG keys

Since ArgoCD currently supports only gpg public keys at the moment, we have to handle the gpg private keys around ArgoCD.

### Method 1: Mount the gpg key from secret as volume
Private keys needs to be mounted externally. helm-secrets is able to import them as needed.

Example Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
spec:
  source:
    helm:
      valueFiles:
        - path/to/values.yaml
        - secrets+gpg-import:///gpg-private-keys/app.asc?path/to/secrets.yaml
        - secrets+gpg-import:///gpg-private-keys/app.asc?https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/sops/values.yaml
```

#### 1. Create Secrets with gpg keys
All gpg keys needs to be available as kubernetes secret. Create the secret in the same namespace where the argocd repo server is running.

```bash
kubectl create secret generic gpg-private-keys --from-file=app.asc
```

#### 2. Attach newly created secrets to ArgoCD repo server

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).

```yaml
repoServer:
  volumes:
    - name: gpg-private-keys
      secret:
        secretName: gpg-private-keys

  volumeMounts:
    - mountPath: /gpg-private-keys/
      name: gpg-private-keys
```

### Method 2: Fetch the gpg key from kubenetes secret
As alternative to Method 1, is avoid the requirement to mount gpg keys inside ArgoCD.

This method requires a installed kubectl binary inside the ArgoCD repo server container and the service account of argocd repo server needs the permission to read secrets.

Example Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
...
spec:
  source:
    helm:
      valueFiles:
        - path/to/values.yaml
        - secrets+gpg-import-kubernetes://argocd/argocd-gpg-key#private.asc?path/to/secrets.yaml
``` 

#### 1. Create Secrets with gpg keys
All gpg keys needs to be available as kubernetes secret. Create the secret in the same namespace where the argocd repo server is running.

```bash
kubectl -n argocd create secret generic gpg-private-keys --from-file=app.asc
```

#### 2. Extends the Kubernetes RBAC Role für repo server

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
