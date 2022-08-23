#!/usr/bin/env bash

# https://github.com/bats-core/bats-core/issues/637
# shellcheck source=tests/lib/helper.bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../lib/helper.bash"

setup_suite() {
    {
        REAL_HOME="${HOME}"
        HOME="${BATS_SUITE_TMPDIR}"
        [ -d "${HOME}" ] || mkdir -p "${HOME}"

        if [ -f "${REAL_HOME}/.gitconfig" ]; then
            cp "${REAL_HOME}/.gitconfig" "${HOME}/.gitconfig"
        fi

        # copy .kube from real home
        if [ -d "${REAL_HOME}/.kube" ]; then
            ln -sf "${REAL_HOME}/.kube" "${HOME}/.kube"
        fi

        define_binaries

        CURRENT_TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
        GIT_ROOT="${CURRENT_TEST_DIR}/../.."

        _uname="$(uname)"
        export _uname
        export HOME
        export GIT_ROOT
        export TEST_ROOT="${GIT_ROOT}/tests"

        export HELM_SECRETS_BACKEND="${HELM_SECRETS_BACKEND:-"sops"}"

        export CACHE_DIR="${TEST_ROOT}/.tmp/cache"
        export HELM_CACHE="${CACHE_DIR}/${_uname}/helm"
        HELM_DATA_HOME="$(_winpath "${HELM_CACHE}")"
        export HELM_DATA_HOME

        mkdir -p "${HELM_CACHE}/home"

        if [ ! -d "${HELM_CACHE}/chart" ]; then
            mkdir -p "${HELM_CACHE}/chart"
            if [[ "${HELM_BIN}" == *"helm.exe" ]]; then
                "${HELM_BIN}" create "$(_winpath "${HELM_CACHE}/chart")"
            else
                "${HELM_BIN}" create "${HELM_CACHE}/chart"
            fi
        fi

        helm_plugin_install "secrets"
        helm_plugin_install "git"

        if [[ "${CURRENT_TEST_DIR}" = *"/it" ]]; then
            helm_plugin_install "diff" --version 3.5.0
        fi

        if on_windows || on_wsl; then
            "${HELM_BIN}" secrets patch windows
        else
            "${HELM_BIN}" secrets patch unix
        fi

        case "${HELM_SECRETS_BACKEND:-sops}" in
        sops)
            GPG_PRIVATE_KEY="$(_winpath "${TEST_ROOT}/assets/gpg/private.gpg")"
            "${GPG_BIN}" --batch --import "${GPG_PRIVATE_KEY}"
            ;;
        vals)
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
            ;;
        esac

        if on_windows; then
            # remove symlink, since its not supported on windows
            find "${TEST_ROOT}" -name secrets.symlink.yaml -delete
        fi
    } >&2
}

teardown_suite() {
    {
        case "${HELM_SECRETS_BACKEND:-sops}" in
        sops)
            "${GPGCONF_BIN}" --kill gpg-agent >&2 || true
            ;;
        esac
    } >&2
}

define_binaries() {
    # MacOS have shasum, others have sha1sum
    if command -v shasum >/dev/null; then
        export SHA1SUM_BIN=shasum
    else
        export SHA1SUM_BIN=sha1sum
    fi

    # cygwin does not have an alias
    if command -v gpg2 >/dev/null; then
        export GPG_BIN=gpg2
    elif command -v gpg.exe >/dev/null; then
        export GPG_BIN=gpg.exe
    else
        export GPG_BIN=gpg
    fi

    if command -v gpgconf.exe >/dev/null; then
        export GPGCONF_BIN=gpgconf.exe
    else
        export GPGCONF_BIN=gpgconf
    fi

    if command -v git.exe >/dev/null; then
        export GIT_BIN=git.exe
    else
        export GIT_BIN=git
    fi

    if command -v helm.exe >/dev/null; then
        export HELM_BIN=helm.exe
    else
        export HELM_BIN=helm
    fi

    if command -v sops.exe >/dev/null; then
        export SOPS_BIN=sops.exe
    else
        export SOPS_BIN=sops
    fi

    if command -v vals.exe >/dev/null; then
        export VALS_BIN=vals.exe
    else
        export VALS_BIN=vals
    fi
}

helm_plugin_install() {
    {
        if "${HELM_BIN}" plugin list | grep -q "${1}"; then
            return
        fi

        case "${1}" in
        diff)
            URL="https://github.com/databus23/helm-diff"
            ;;
        git)
            URL="https://github.com/aslafy-z/helm-git"
            ;;
        secrets)
            URL="$(_winpath "${GIT_ROOT}")"
            ;;
        esac

        "${HELM_BIN}" plugin install "${URL}" "${@:2}"
    } >&2
}
