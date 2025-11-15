#!/usr/bin/env bash

load '../lib/helper'
load '../lib/binaries'

setup_suite() {
    {
        export HELM_SECRETS_BACKEND="${HELM_SECRETS_BACKEND:-"sops"}"
        export HELM_SECRETS_CUSTOM_BACKEND=${HELM_SECRETS_CUSTOM_BACKEND:-""}

        if [[ "${HELM_SECRETS_BACKEND}" == "custom-"* ]]; then
            HELM_SECRETS_CUSTOM_BACKEND="${HELM_SECRETS_BACKEND}"
            unset HELM_SECRETS_BACKEND
        fi

        REAL_HOME="${HOME}"
        export HOME="${BATS_SUITE_TMPDIR}"
        [ -d "${HOME}" ] || mkdir -p "${HOME}"

        _uname="$(uname)"
        export _uname

        if [ -f "${REAL_HOME}/.gitconfig" ]; then
            cp "${REAL_HOME}/.gitconfig" "${HOME}/.gitconfig"
        fi

        # copy .kube from real home
        if [ -d "${REAL_HOME}/.kube" ]; then
            ln -sf "${REAL_HOME}/.kube" "${HOME}/.kube"
        fi

        CURRENT_TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
        export GIT_ROOT="${CURRENT_TEST_DIR}/../.."
        export TEST_ROOT="${GIT_ROOT}/tests"

        export CACHE_DIR="${TEST_ROOT}/.tmp/cache"
        export HELM_CACHE="${CACHE_DIR}/${_uname}/helm"

        mkdir -p "${HELM_CACHE}"

        HELM_DATA_HOME="$(_winpath "${HELM_CACHE}")"
        export HELM_DATA_HOME

        if [ ! -d "${HELM_CACHE}/chart/${HELM_SECRETS_BACKEND}/" ]; then
            mkdir -p "${HELM_CACHE}/chart/${HELM_SECRETS_BACKEND}/"
            "${HELM_BIN}" create "$(_winpath "${HELM_CACHE}/chart/${HELM_SECRETS_BACKEND}")"

            if [ -d "${TEST_ROOT}/assets/values/${HELM_SECRETS_BACKEND}/templates/base/" ]; then
                cp -r "${TEST_ROOT}/assets/values/${HELM_SECRETS_BACKEND}/templates/base/." "${HELM_CACHE}/chart/${HELM_SECRETS_BACKEND}/templates/"
            fi
        fi

        helm_plugin_install "secrets"
        helm_plugin_install "git"

        if [[ "${CURRENT_TEST_DIR}" = *"/it" ]]; then
            helm_plugin_install "diff" --version 3.5.0
        fi

        mkdir -p "$HOME/.gnupg/"
        touch "$HOME/.gnupg/common.conf"

        GPG_PRIVATE_KEY="$(_winpath "${TEST_ROOT}/assets/gpg/private.gpg")"
        "${GPG_BIN}" --batch --import "${GPG_PRIVATE_KEY}"
        export _TEST_KEY="-----BEGIN PGP MESSAGE-----
wcFMAxYpv4YXKfBAARAAVzE7/FMD7+UWwMls23zKKLoTs+5w9GMvugn0wi5KOJ8P
PSrRY4r27VhwQH38gWDrzo3RCmO9414xZ0JW0HaN2Pgd3ml6mYCY/5RE7apgGZQI
3Im0fv8bhIwaP2UWPp74EXLzA3mh1dUtwxmuWOeoSq+Vm5NtbjkfUt/4MIcF5IAY
c+U4ZOdQlzgExwu+VtOpeBrkwfglh5fFuKqM8Fg1IICi/Pp6YAlpAdGqlt1zS4Pj
yjAS6eAvnpM0eA5hShuoO9JsAu4kVjaaBlipVpc1I2zdcT3H/1d7ASziwbKOm6jE
PJxzaMDxn0UfMjkhTaTZ8v27lz6W7qdlHdCWGGI348QkSoDotm7OzMC7ZLfps3+9
GrXo9Kwxkj6oy/thn92W2cRSeSD28g6kcUkHeG8L3mMv+gpTjIhM+Z8x3jJcVp2i
yoA2dO/kO2/HTcUfnEjppKigqUlRuKfDn8ercjYiq+foqtimH192iXXyRmltYlH0
GUSJ1FcNLAC9g0WLFPQnMFh5KxSweavpbdd6PILqEsyKvZpC5a+hzLKwGjWOveW1
K34QZf6Ay3CPCegAyGVjxmsg1vPKD+9WAZinveCl37l3cCQW1VZzbGkHgtLQ30Qr
DCRFZEstraLAQUf6VLAk9bPYX/fvkXmra970i/CfJjIg0SpOXbADBR4x+zRRZqrS
4AHkWTmhH/xXWyAgmh+sGs18OOFGfeC04AjhMmvg4uKzly6+4IDlNhPif2VpJYOi
EmU8gQoUsAHKYro0hPfzBZyJlL+TqCPgHeRPANVgm4Ww6RlVrNFpTy9H4m4s5y/h
EzAA
=jf7D
-----END PGP MESSAGE-----"
        export _TEST_global_secret=global_bar
        export _TEST_SERVICE_PORT=81
        export _TEST_SOME_SERVICE_PORT=83

        if on_windows; then
            # remove symlink, since its not supported on windows
            find "${TEST_ROOT}" -name secrets.symlink.yaml -delete
        fi
    } >&2
}

teardown_suite() {
    {
        "${GPGCONF_BIN}" --kill gpg-agent
    } >&3
}

helm_plugin_install() {
    {
        if "${HELM_BIN}" plugin list | grep -q "${1}"; then
            return
        fi

        case "${1}" in
        diff)
            URL="https://github.com/databus23/helm-diff"
            # renovate: github=databus23/helm-diff
            VERSION=v3.11.0
            ;;
        git)
            URL="https://github.com/aslafy-z/helm-git"
            # renovate: github=aslafy-z/helm-git
            VERSION=v1.3.0
            ;;
        secrets)
            URL="$(_winpath "${GIT_ROOT}")"
            if helm_version_greater_or_equal_than 4.0.0; then
                "${HELM_BIN}" plugin install "${URL}/plugins/helm-secrets-getter"
                URL="${URL}/plugins/helm-secrets-cli"
            fi
            ;;
        esac

        VERIFY=""

        if helm_version_greater_or_equal_than 4.0.0; then
            VERIFY="--verify=false"
        fi

        "${HELM_BIN}" plugin install "${URL}" "${@:2}" ${VERSION:+--version "${VERSION}"} ${VERIFY}
    } >&2
}
