FROM alpine

ARG VERSION_HELM=3.11.0
ARG VERSION_SOPS=3.7.3
ARG VERSION_VALS=0.24.0

RUN apk add git curl gnupg ruby bash \
    && curl -sSfL https://github.com/getsops/sops/releases/download/v${VERSION_SOPS}/sops-v${VERSION_SOPS}.linux -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops \
    && curl -sSfL https://get.helm.sh/helm-v${VERSION_HELM}-linux-amd64.tar.gz | tar xzf - --strip-component 1 -C /usr/local/bin/ \
    && curl -sSfL https://github.com/variantdev/vals/releases/download/v${VERSION_VALS}/vals_${VERSION_VALS}_linux_amd64.tar.gz | tar xzf - -C /usr/local/bin/ vals \
    && gem install bashcov simplecov-cobertura

ENV BATSLIB_TEMP_PRESERVE="0" BATSLIB_TEMP_PRESERVE_ON_FAILURE="0"

WORKDIR /helm-secrets/
ENTRYPOINT ["/helm-secrets/tests/bats/core/bin/bats"]
CMD [ "tests/unit/helm-plugin.bats"]
