GIT_ROOT="$(git rev-parse --show-toplevel)"
TEST_DIR="${GIT_ROOT}/tests"
HELM_SECRETS_DRIVER="${HELM_SECRETS_DRIVER:-"sops"}"
HELM_CACHE="${TEST_DIR}/.tmp/cache/$(uname)/helm"
REAL_HOME="${HOME}"

is_windows() {
    ! [[ "$(uname)" == "Darwin" || "$(uname)" == "Linux" ]]
}

is_driver_sops() {
    [ "${HELM_SECRETS_DRIVER}" == "sops" ]
}

is_coverage() {
    [ -n "${BASHCOV_COMMAND_NAME+x}" ]
}

is_curl_installed() {
    command -v curl >/dev/null
}

_shasum() {
    # MacOS have shasum, others have sha1sum
    if command -v shasum >/dev/null; then
        shasum "$@"
    else
        sha1sum "$@"
    fi
}

_sed_i() {
    # MacOS syntax is different for in-place
    if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

initiate() {
    {
        mkdir -p "${HELM_CACHE}/home"
        if [ ! -d "${HELM_CACHE}/chart" ]; then
            helm create "${HELM_CACHE}/chart"
        fi
    } >&2
}

setup() {
    # https://github.com/bats-core/bats-core/issues/39
    if [[ ${BATS_TEST_NAME:?} == "${BATS_TEST_NAMES[0]:?}" ]]; then
        initiate
    fi

    SEED="${RANDOM}"

    TEST_TEMP_DIR="$(TMPDIR="${W_TEMP:-/tmp/}" mktemp -d)"
    TEST_TEMP_HOME="$(mktemp -d)"
    HOME="${TEST_TEMP_HOME}"

    # shellcheck disable=SC2034
    XDG_DATA_HOME="${HOME}"

    # Windows
    # See: https://github.com/helm/helm/blob/b4f8312dbaf479e5f772cd17ae3768c7a7bb3832/pkg/helmpath/lazypath_windows.go#L22
    # shellcheck disable=SC2034
    APPDATA="${HOME}"

    # shellcheck disable=SC2016
    SPECIAL_CHAR_DIR="${TEST_TEMP_DIR}/$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')"

    mkdir "${TEST_TEMP_DIR}/chart"
    if [[ "$(uname)" == "Darwin" || "$(uname)" == "Linux" ]]; then
        mkdir "${SPECIAL_CHAR_DIR}"
    fi

    # install helm plugin
    helm plugin install "${GIT_ROOT}"

    # copy .kube from real home
    if [ -d "${REAL_HOME}/.kube" ]; then
        cp -r "${REAL_HOME}/.kube" "${HOME}"
    fi

    # copy assets
    cp -r "${TEST_DIR}/assets/." "${TEST_TEMP_DIR}"
    if [[ "$(uname)" == "Darwin" || "$(uname)" == "Linux" ]]; then
        cp -r "${TEST_DIR}/assets/." "$(printf '%s' "${SPECIAL_CHAR_DIR}")"
    fi

    cp -r "${TEST_DIR}/assets/values/sops/.sops.yaml" "${TEST_TEMP_DIR}"

    # import default gpg key
    gpg --batch --import "${TEST_DIR}/assets/gpg/private.gpg"

    case "${HELM_SECRETS_DRIVER}" in
    sops) ;;

    vault)
        if [ -f .dockerenv ]; then
            # If we run inside docker, we expect vault on this location
            export VAULT_ADDR=${VAULT_ADDR:-'http://vault:8200'}
        else
            export VAULT_ADDR=${VAULT_ADDR:-'http://127.0.0.1:8200'}
        fi

        vault login token=test

        _sed_i "s!put secret/!put secret/${SEED}/!g" "$(printf '%s/values/vault/seed.sh' "${TEST_TEMP_DIR}")"

        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/values/vault/secrets.yaml' "${TEST_TEMP_DIR}")"
        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/values/vault/secrets.yaml' "${SPECIAL_CHAR_DIR}")"

        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/values/vault/some-secrets.yaml' "${TEST_TEMP_DIR}")"
        _sed_i "s!vault secret/!vault secret/${SEED}/!g" "$(printf '%s/values/vault/some-secrets.yaml' "${SPECIAL_CHAR_DIR}")"

        sh "${TEST_TEMP_DIR}/values/vault/seed.sh"
        ;;
    esac
}

teardown() {
    # https://stackoverflow.com/a/13864829/8087167
    if [ -n "${RELEASE+x}" ]; then
        helm del "${RELEASE}"
    fi

    # https://github.com/bats-core/bats-file/pull/29
    chmod -R 777 "${TEST_TEMP_DIR}"

    # rm: cannot remove '/tmp/tmp.11dcSX0g8Q/home/.gnupg/S.gpg-agent.browser': No such file or directory
    rm -rf "${TEST_TEMP_DIR}/home/.gnupg/"

    temp_del "${TEST_TEMP_DIR}"
    temp_del "${TEST_TEMP_HOME}"
}

create_chart() {
    {
        cp -r "${HELM_CACHE}/chart" "${1}"
        cp -r "${TEST_TEMP_DIR}/values" "${1}/chart"
        cp "${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml" "${1}/chart"
    } >&2
}

helm_plugin_install() {
    {
        if ! env APPDATA="${HELM_CACHE}/home/" HOME="${HELM_CACHE}/home/" helm plugin list | grep -q "${1}"; then
            case "${1}" in
            kubeval)
                URL="https://github.com/instrumenta/helm-kubeval"
                ;;
            diff)
                URL="https://github.com/databus23/helm-diff"
                ;;
            git)
                URL="https://github.com/aslafy-z/helm-git"
                ;;
            esac

            env APPDATA="${HELM_CACHE}/home/" HOME="${HELM_CACHE}/home/" helm plugin install "${URL}" ${VERSION:+--version ${VERSION}}

            # prevent temp_del to block on write-protected git objects
            chmod -R +w "${HELM_CACHE}/home/.cache/helm/" "${HELM_CACHE}/home/.local/share/helm/"
        fi

        cp -r "${HELM_CACHE}/home/." "${HOME}"
    } >&2
}
