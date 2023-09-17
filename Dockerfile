FROM alpine:latest

ARG VERSION_HELM=3.11.0
ARG VERSION_SOPS=3.8.0
ARG VERSION_VALS=0.24.0
ARG VERSION_KUBECTL=0.21.0

SHELL ["/bin/sh", "-exc"]

ENV HOME=/home/user/

RUN if [ "$(uname -m)" == "x86_64" ]; then CURL_ARCH=amd64; GO_ARCH=amd64; else CURL_ARCH="aarch64" GO_ARCH="arm64"; fi \
    && apk add --no-cache gnupg curl && adduser -D user \
    && wget -qO /usr/local/bin/sops https://github.com/getsops/sops/releases/download/v${VERSION_SOPS}/sops-v${VERSION_SOPS}.linux.${GO_ARCH} \
    && wget -qO /usr/local/bin/kubectl https://dl.k8s.io/release/v${VERSION_KUBECTL}/bin/linux/${GO_ARCH}/kubectl \
    && wget -qO - https://get.helm.sh/helm-v${VERSION_HELM}-linux-${GO_ARCH}.tar.gz | tar xzvf - -C /usr/local/bin/ --strip-components 1 "linux-${GO_ARCH}/helm" \
    && wget -qO - https://github.com/variantdev/vals/releases/download/v${VERSION_VALS}/vals_${VERSION_VALS}_linux_amd64.tar.gz | tar xzf - -C /usr/local/bin/ vals \
    && chmod +x /usr/local/bin/*

COPY scripts/ /home/user/.local/share/helm/plugins/helm-plugins/scripts/
COPY plugin.yaml /home/user/.local/share/helm/plugins/helm-plugins/

USER user

