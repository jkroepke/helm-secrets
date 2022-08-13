#!/usr/bin/env sh

# shellcheck disable=SC2034
_BACKEND_REGEX='!vault [A-z0-9][A-z0-9/*\.\_\-]*\#[A-z0-9*\.\_\-][A-z0-9*\.\_\-]*'

. "${HELM_SECRETS_SCRIPT_DIR}/backends/_custom.sh"

_custom_backend_get_secret() {
    _type=$1
    _SECRET=$2

    if [ "${_type}" != "yaml" ]; then
        echo "Only decryption of yaml files are allowed!"
        exit 1
    fi

    if ! echo "${_SECRET}"; then
        echo "Error while get secret!" >&2
        exit 1
    fi
}
