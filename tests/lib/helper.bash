#!/usr/bin/env bash

load '../lib/binaries.bash'
export WSLENV="${WSLENV:-}"

is_driver() {
    [ "${HELM_SECRETS_DRIVER}" == "${1}" ]
}

is_coverage() {
    [ -n "${BASHCOV_COMMAND_NAME+x}" ]
}

is_curl_installed() {
    command -v curl >/dev/null
}

_sed_i() {
    # MacOS syntax is different for in-place
    if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

on_windows() {
    _uname="$(uname)"
    ! [[ "${_uname}" == "Darwin" || "${_uname}" == "Linux" ]] || on_wsl
}

on_linux() {
    _uname="$(uname)"
    [[ "${_uname}" == "Linux" ]]
}

on_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

_mktemp() {
    if [[ -n "${TMPDIR+x}" && "${TMPDIR}" != "" ]]; then
        TMPDIR="${TMPDIR}" mktemp "$@"
    else
        mktemp "$@"
    fi
}

_home_dir() {
    printf '%s' "/tmp/helm-secrets-test.${BATS_ROOT_PID}/$(basename "${BATS_TEST_FILENAME}")/home"
}

_copy() {
    if on_windows; then
        cp -r "$@"
    else
        ln -sf "$@"
    fi
}

initiate() {
    {
        # BATS_SUITE_TMPDIR
        mkdir -p "${HELM_CACHE}/home"

        if [ ! -d "${HELM_CACHE}/chart" ]; then
            mkdir -p "${HELM_CACHE}/chart"
            if on_wsl; then
                echo "${HELM_BIN}" create "$(wslpath -w "${HELM_CACHE}/chart")"
                ls -lah "${HELM_CACHE}/chart"
                "${HELM_BIN}" create "$(wslpath -w "${HELM_CACHE}/chart")"
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

        case "${HELM_SECRETS_DRIVER:-sops}" in
        vault)
            vault server -dev -dev-root-token-id=test &>/dev/null &
            echo "$!" > "${HOME}/vault.pid"
            sleep 0.5
            vault login token=test
            sh "${TEST_DIR}/assets/values/vault/seed.sh"
            ;;
        *)
            GPG_PRIVATE_KEY="${TEST_DIR}/assets/gpg/private.gpg"

            if on_wsl; then
                GPG_PRIVATE_KEY="$(wslpath -w "${GPG_PRIVATE_KEY}")"
            fi

            "${GPG_BIN}" --batch --import "${GPG_PRIVATE_KEY}"
            ;;
        esac
    } >&2
}

setup() {
    REAL_HOME="${HOME}"
    # shellcheck disable=SC2153
    HOME="$(_home_dir)"

    [ -d "${HOME}" ] || mkdir -p "${HOME}"
    export HOME

    if [ -f "${REAL_HOME}/.gitconfig" ]; then
        cp "${REAL_HOME}/.gitconfig" "${HOME}/.gitconfig"
    fi

    define_binaries

    GIT_ROOT="$("${GIT_BIN}" rev-parse --show-toplevel)"
    if on_wsl; then
        GIT_ROOT="$(wslpath "${GIT_ROOT}")"
    fi

    TEST_DIR="${GIT_ROOT}/tests"

    # shellcheck disable=SC2164
    cd "${TEST_DIR}"

    HELM_SECRETS_DRIVER="${HELM_SECRETS_DRIVER:-"sops"}"

    CACHE_DIR="${TEST_DIR}/.tmp/cache"
    HELM_CACHE="${CACHE_DIR}/$(uname)/helm"
    HELM_DATA_HOME="${HELM_CACHE}"
    export HELM_DATA_HOME

    export VAULT_ADDR=${VAULT_ADDR:-'http://127.0.0.1:8200'}

    # shellcheck disable=SC2034
    SEED="${RANDOM}"

    # Windows TMPDIR behavior
    if [[ "$(uname -s)" == CYGWIN* ]]; then
        TMPDIR="$(cygpath -m "${TEMP}")"
    elif on_wsl; then
        TMPDIR="$(wslpath "${TEMP}")"
    elif [ -n "${W_TEMP+x}" ]; then
        TMPDIR="${W_TEMP}"
    fi

    # https://github.com/bats-core/bats-core/issues/39#issuecomment-377015447
    if [[ "$BATS_TEST_NUMBER" -eq 1 ]]; then
        initiate
    fi

    TEST_TEMP_DIR="$(_mktemp -d)"

    # copy .kube from real home
    if [ -d "${REAL_HOME}/.kube" ]; then
        ln -sf "${REAL_HOME}/.kube" "${HOME}/.kube"
    fi

    if on_windows; then
        # remove symlink, since its not supported on windows
        find "${TEST_DIR}" -name secrets.symlink.yaml -delete
    fi

    # copy assets
    cp -a "${TEST_DIR}/assets" "${TEST_TEMP_DIR}/"
    if ! on_windows; then
        # shellcheck disable=SC2016
        SPECIAL_CHAR_DIR="${TEST_TEMP_DIR}/$(printf '%s' 'a@b§c!d\$e \f(g)h=i^j😀')"
        mkdir "${SPECIAL_CHAR_DIR}"
        cp -a "${TEST_DIR}/assets" "${SPECIAL_CHAR_DIR}/"
    fi

    _copy "${TEST_DIR}/assets/values/sops/.sops.yaml" "${TEST_TEMP_DIR}"
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
}

teardown() {
    # https://stackoverflow.com/a/13864829/8087167
    if [ -n "${RELEASE+x}" ]; then
        "${HELM_BIN}" del "${RELEASE}" >&2
    fi

    # https://github.com/bats-core/bats-core/issues/39#issuecomment-377015447
    if [[ "${#BATS_TEST_NAMES[@]}" -eq "$BATS_TEST_NUMBER" ]]; then
        "${GPGCONF_BIN}" --kill gpg-agent >&2

        case "${HELM_SECRETS_DRIVER:-sops}" in
        vault)
            kill -9 "$(cat "$(_home_dir)/vault.pid")"
            ;;
        esac

        temp_del "$(_home_dir)"
    fi

    if [ -n "${TEST_TEMP_DIR+x}" ]; then
        # https://github.com/bats-core/bats-file/pull/29
        chmod -R 777 "${TEST_TEMP_DIR}" >&2
        temp_del "${TEST_TEMP_DIR}"
    fi
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
            URL="${GIT_ROOT}"
            ;;
        esac

        "${HELM_BIN}" plugin install "${URL}" "${@:2}"
    } >&2
}
