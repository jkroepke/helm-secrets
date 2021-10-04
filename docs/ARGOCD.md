# Argo CD Integration

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
        - gpg-import+secrets://path/to/app.asc?path/to/secrets.yaml
``` 

### External Chart and local values
Please mention, this won't work with external helm charts, subscribe https://github.com/argoproj/argo-cd/issues/7257 for more infos.

## Install helm-secrets and sops

### Method 1: Custom Server Image
Integrating `helm-secrets` with Argo CD can be achieved by building a custom Argo CD server image.

Below is an example `Dockerfile` which incorporates `sops` and `helm-secrets` into the Argo CD image:
```Dockerfile
ARG ARGOCD_VERSION="v2.1.2"
FROM argoproj/argocd:$ARGOCD_VERSION
ARG SOPS_VERSION="3.7.1"
ARG HELM_SECRETS_VERSION="3.8.3"

USER root
RUN apt-get update && \
    apt-get install -y \
      curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl -fSSL https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux \
    -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops

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
        - name: SOPS_VERSION
          value: "3.7.1"
        - name: HELM_SECRETS_VERSION
          value: "3.8.3"
      args:
        - |
          wget -qO /custom-tools/sops https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux
          chmod +x /custom-tools/sops
          mkdir -p /custom-tools/helm-plugins
          wget -qO- https://github.com/jkroepke/helm-secrets/releases/download/v${HELM_SECRETS_VERSION}/helm-secrets.tar.gz | tar -C /custom-tools/helm-plugins -xzf-;
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
```

## GPG keys

ArgoCD currently supports only gpg public keys at the moment.

Private keys needs to be mounted externally. helm-secrets is able to import them as needed.

### 1. Create Secrets with gpg keys
All gpg keys needs to be available as kubernetes secret.

```bash
kubectl create secret generic gpg-private-keys --from-file=app.asc
```

### 2. Attach newly created secrets to argocd repo server

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
