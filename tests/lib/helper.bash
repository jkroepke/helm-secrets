#!/usr/bin/env bash

load '../lib/binaries.bash'
export WSLENV="${WSLENV:-}"

is_backend() {
    [[ "${HELM_SECRETS_BACKEND}" == "${1}" ]]
}

on_windows() {
    ! [[ "${_uname}" == "Darwin" || "${_uname}" == "Linux" ]] || on_wsl
}

on_linux() {
    [[ "${_uname}" == "Linux" ]]
}

on_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

on_cygwin() {
    [[ "${_uname}" == "CYGWIN"* ]]
}

_winpath() {
    if on_wsl; then
        touch "${1}"
        printf '%s' "$(wslpath -w "${1}")"
    elif on_cygwin; then
        touch "${1}"
        printf '%s' "$(cygpath -w -l "${1}")"
    else
        printf '%s' "${1}"
    fi
}

_copy() {
    if on_windows; then
        ln -sf "$@"
    else
        ln -sf "$@"
    fi
}

setup_file() {
    {
        REAL_HOME="${HOME}"
        HOME="${BATS_FILE_TMPDIR}"
        [ -d "${HOME}" ] || mkdir -p "${HOME}"

        if [ -f "${REAL_HOME}/.gitconfig" ]; then
            cp "${REAL_HOME}/.gitconfig" "${HOME}/.gitconfig"
        fi

        # copy .kube from real home
        if [ -d "${REAL_HOME}/.kube" ]; then
            ln -sf "${REAL_HOME}/.kube" "${HOME}/.kube"
        fi

        define_binaries

        GIT_ROOT="${BATS_TEST_DIRNAME}/../.."

        _uname="$(uname)"
        export _uname
        export HOME
        export GIT_ROOT
        export TEST_DIR="${GIT_ROOT}/tests"

        export HELM_SECRETS_BACKEND="${HELM_SECRETS_BACKEND:-"sops"}"

        export CACHE_DIR="${TEST_DIR}/.tmp/cache"
        export HELM_CACHE="${CACHE_DIR}/${_uname}/helm"
        export VAULT_ADDR=${VAULT_ADDR:-'http://127.0.0.1:8200'}
        HELM_DATA_HOME="$(_winpath "${HELM_CACHE}")"
        export HELM_DATA_HOME

        # BATS_SUITE_TMPDIR
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
        if [[ "${BATS_TEST_FILENAME}" = *"/it/"* ]]; then
            helm_plugin_install "diff" --version 3.1.3
        fi

        if on_windows || on_wsl; then
            "${HELM_BIN}" secrets patch windows
        else
            "${HELM_BIN}" secrets patch unix
        fi

        case "${HELM_SECRETS_BACKEND:-sops}" in
        sops)
            GPG_PRIVATE_KEY="${TEST_DIR}/assets/gpg/private.gpg"
            if on_wsl; then
                GPG_PRIVATE_KEY="$(wslpath -w "${GPG_PRIVATE_KEY}")"
            fi
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
            find "${TEST_DIR}" -name secrets.symlink.yaml -delete
        fi
    } >&2
}

setup() {
    {
        # shellcheck disable=SC2164
        cd "${TEST_DIR}"
        # shellcheck disable=SC2034
        SEED="${RANDOM}"

        TEST_TEMP_DIR="$(mktemp -d)"
        export TEST_TEMP_DIR

        # copy assets
        cp -a "${TEST_DIR}/assets" "${TEST_TEMP_DIR}/"
        if ! on_windows; then
            # shellcheck disable=SC2016
            SPECIAL_CHAR_DIR="${TEST_TEMP_DIR}/$(printf '%s' 'a@b§c!d\$e \f(g)h=i^j😀')"
            mkdir "${SPECIAL_CHAR_DIR}"
            cp -a "${TEST_DIR}/assets" "${SPECIAL_CHAR_DIR}/"
        fi

        _copy "${TEST_DIR}/assets/values/sops/.sops.yaml" "${TEST_TEMP_DIR}"
    } >&2
}

teardown() {
    {
        # https://stackoverflow.com/a/13864829/8087167
        if [ -n "${RELEASE+x}" ]; then
            "${HELM_BIN}" del "${RELEASE}" || true
        fi
    } >&2
}

teardown_file() {
    {
        case "${HELM_SECRETS_BACKEND:-sops}" in
        sops)
            "${GPGCONF_BIN}" --kill gpg-agent >&2 || true
            ;;
        esac
    } >&2
}

create_chart() {
    {
        _copy "${HELM_CACHE}/chart/" "${1}"
    } >&2
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
