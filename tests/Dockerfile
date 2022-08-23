FROM ubuntu:22.04

ARG VERSION_HELM=v3.9.0
ARG VERSION_SOPS=v3.7.3

RUN apt-get update -qq && apt-get install -yqq git-core curl gnupg2 ruby \
    && curl -sSfL https://github.com/mozilla/sops/releases/download/${VERSION_SOPS}/sops-${VERSION_SOPS}.linux -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops \
    && curl -sSfL https://get.helm.sh/helm-${VERSION_HELM}-linux-amd64.tar.gz | tar xzf - --strip-component 1 -C /usr/local/bin/ --wildcards '*/helm' \
    && gem install bashcov simplecov-cobertura

ENV BATSLIB_TEMP_PRESERVE="0" BATSLIB_TEMP_PRESERVE_ON_FAILURE="0"

WORKDIR /work
ENTRYPOINT ["/work/tests/bats/core/bin/bats"]
CMD [ "tests/unit/helm-plugin.bats"]
