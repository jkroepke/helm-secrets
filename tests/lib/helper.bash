#!/usr/bin/env bash
is_driver() {
    [ "${HELM_SECRETS_DRIVER}" == "${1}" ]
}

is_coverage() {
    [ -n "${BASHCOV_COMMAND_NAME+x}" ]
}

is_curl_installed() {
    command -v curl >/dev/null
}

on_windows() {
    _uname="$(uname)"; ! [[ "${_uname}" == "Darwin" || "${_uname}" == "Linux" ]]
}

_sed_i() {
    # MacOS syntax is different for in-place
    if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

_shasum() {
    # MacOS have shasum, others have sha1sum
    if command -v shasum >/dev/null; then
        shasum "$@"
    else
        sha1sum "$@"
    fi
}

_gpg() {
    # cygwin does not have an alias
    if command -v gpg2 >/dev/null; then
        gpg2 "$@"
    else
        gpg "$@"
    fi
}

_mktemp() {
    if [[ -n "${TMPDIR+x}" && "${TMPDIR}" != "" ]]; then
        TMPDIR="${TMPDIR}" mktemp "$@"
    else
        mktemp "$@"
    fi
}

_home_dir() {
    printf '%s' "${BATS_RUN_TMPDIR}/$(basename "${BATS_TEST_FILENAME}")/home"
}

initiate() {
    {
        mkdir -p "${HELM_CACHE}/home"
        _gpg --batch --import "${TEST_DIR}/assets/gpg/private.gpg"

        if [ ! -d "${HELM_CACHE}/chart" ]; then
            helm create "${HELM_CACHE}/chart"
        fi

        helm_plugin_install "secrets"
        helm_plugin_install "diff" --version 3.1.3
        helm_plugin_install "git"
    } >&2
}

setup() {
    REAL_HOME="${HOME}"
    # shellcheck disable=SC2153
    HOME="$(_home_dir)"
    [ -d "${HOME}" ] || mkdir -p "${HOME}"
    export HOME

    GIT_ROOT="$(git rev-parse --show-toplevel)"
    TEST_DIR="${GIT_ROOT}/tests"
    HELM_SECRETS_DRIVER="${HELM_SECRETS_DRIVER:-"sops"}"

    CACHE_DIR="${TEST_DIR}/.tmp/cache"
    HELM_CACHE="${CACHE_DIR}/$(uname)/helm"
    HELM_DATA_HOME="${HELM_CACHE}"
    export HELM_DATA_HOME

    SEED="${RANDOM}"

    # Windows TMPDIR behavior
    if [[ "$(uname -s)" == CYGWIN* ]]; then
        TMPDIR="$(cygpath -m "${TEMP}")"
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

    # copy assets
    cp -r "${TEST_DIR}/assets" "${TEST_TEMP_DIR}/"
    if [[ "$(uname)" == "Darwin" || "$(uname)" == "Linux" ]]; then
        # shellcheck disable=SC2016
        SPECIAL_CHAR_DIR="${TEST_TEMP_DIR}/$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')"
        mkdir "${SPECIAL_CHAR_DIR}"
        cp -r "${TEST_DIR}/assets" "${SPECIAL_CHAR_DIR}/"
    fi

    ln -sf "${TEST_DIR}/assets/values/sops/.sops.yaml" "${TEST_TEMP_DIR}"

    case "${HELM_SECRETS_DRIVER:-sops}" in
    vault)
        if [ -f .dockerenv ]; then
            # If we run inside docker, we expect vault on this location
            export VAULT_ADDR=${VAULT_ADDR:-'http://vault:8200'}
        else
            export VAULT_ADDR=${VAULT_ADDR:-'http://127.0.0.1:8200'}
        fi

        vault login token=test

        _sed_i "s!put secret/!put secret/${SEED}/!g" "$(printf '%s/assets/values/vault/seed.sh' "${TEST_TEMP_DIR}")"

        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/assets/values/vault/secrets.yaml' "${TEST_TEMP_DIR}")"
        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/assets/values/vault/secrets.yaml' "${SPECIAL_CHAR_DIR}")"

        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/assets/values/vault/some-secrets.yaml' "${TEST_TEMP_DIR}")"
        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/assets/values/vault/some-secrets.yaml' "${SPECIAL_CHAR_DIR}")"

        sh "${TEST_TEMP_DIR}/assets/values/vault/seed.sh"
        ;;
    esac

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
        helm del "${RELEASE}" >&2
    fi

    # https://github.com/bats-core/bats-core/issues/39#issuecomment-377015447
    if [[ "${#BATS_TEST_NAMES[@]}" -eq "$BATS_TEST_NUMBER" ]]; then
        gpgconf --kill gpg-agent >&2
        temp_del "$(_home_dir)"
    fi

    # https://github.com/bats-core/bats-file/pull/29
    chmod -R 777 "${TEST_TEMP_DIR}" >&2

    temp_del "${TEST_TEMP_DIR}"
}

create_chart() {
    {
        ln -sf "${HELM_CACHE}/chart/" "${1}"
    } >&2
}

helm_plugin_install() {
    {
        if helm plugin list | grep -q "${1}"; then
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

        helm plugin install "${URL}" "${@:2}"
    } >&2
}
