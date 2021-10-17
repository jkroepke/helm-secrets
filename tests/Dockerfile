FROM ubuntu:20.04

RUN apt-get update -qq && apt-get install -yqq git-core curl gnupg2 ruby \
    && curl -sSfL https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.linux -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops \
    && curl -sSfL https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz | tar xzf - --strip-component 1 -C /usr/local/bin/ --wildcards '*/helm' \
    && gem install bashcov simplecov-cobertura

ENV BATSLIB_TEMP_PRESERVE="0" BATSLIB_TEMP_PRESERVE_ON_FAILURE="0"

WORKDIR /work
CMD ["/work/tests/bats/core/bin/bats", "tests/unit/helm-plugin.bats"]
