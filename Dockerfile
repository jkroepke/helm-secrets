FROM alpine:latest

ENV PATH="$PATH:/opt/custom-tools/" \
    SOPS_VERSION=3.7.2 \
    HELM_VERSION=3.8.2 \
    KUBECTL_VERSION=1.23.5

RUN apk add --no-cache gnupg

SHELL ["/bin/sh", "-exc"]

WORKDIR /opt/custom-tools/helm-plugins
COPY scripts/ /opt/custom-tools/helm-plugins/scripts/
COPY plugin.yaml /opt/custom-tools/helm-plugins/

RUN if [ "$(uname -m)" == "x86_64" ]; then CURL_ARCH=amd64; GO_ARCH=amd64; else CURL_ARCH="aarch64" GO_ARCH="arm64"; fi \
    && wget -qO /opt/custom-tools/curl https://github.com/moparisthebest/static-curl/releases/latest/download/curl-${CURL_ARCH} \
    && wget -qO /opt/custom-tools/sops https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${GO_ARCH} \
    && wget -qO /opt/custom-tools/kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${GO_ARCH}/kubectl \
    && wget -qO - https://get.helm.sh/helm-v${HELM_VERSION}-linux-${GO_ARCH}.tar.gz | tar xzvf - -C /usr/local/bin/ --strip-components 1 "linux-${GO_ARCH}/helm" \
    && chmod +x /opt/custom-tools/* /usr/local/bin/helm \
    && /opt/custom-tools/curl --version && /opt/custom-tools/sops --version && /opt/custom-tools/kubectl version --client --short && /usr/local/bin/helm version --short

USER 1001

