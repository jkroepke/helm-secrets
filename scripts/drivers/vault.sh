#!/usr/bin/env sh

_VAULT="${HELM_SECRETS_VAULT_PATH:-vault}"

# shellcheck disable=SC2034
_DRIVER_REGEX='!vault [A-z0-9][A-z0-9/*\.\_\-]*\#[A-z0-9*\.\_\-][A-z0-9*\.\_\-]*'

# shellcheck source=scripts/drivers/_custom.sh
. "${SCRIPT_DIR}/drivers/_custom.sh"

_vault() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"
    $_VAULT "$@"
}

_custom_driver_get_secret() {
    _type=$1
    _SECRET_PATH="${2%#*}"
    _SECRET_FIELD="${2#*#}"

    if [ "${_type}" != "yaml" ]; then
        fatal 'Only decryption of yaml files are allowed!'
    fi

    if ! _vault kv get -format="${_type}" -field="${_SECRET_FIELD}" "${_SECRET_PATH}"; then
        echo 'Error while get secret from vault!' >&2
        echo vault kv get -format="${_type}" -field="${_SECRET_FIELD}" "${_SECRET_PATH}" "${SECRET_DRIVER_ARGS}" >&2
        exit 1
    fi
}

_custom_driver_is_yaml() {
    _type=$1
    _SECRET_PATH="${2%#*}"
    _SECRET_FIELD="${2#*#}"

    [ "${_SECRET_FIELD}" = "data" ]
}
