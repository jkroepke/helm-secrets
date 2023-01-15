#!/usr/bin/env sh

# shellcheck disable=SC2034
_BACKEND_REGEX='!vault [A-z0-9][A-z0-9/*\.\_\-]*\#[A-z0-9*\.\_\-][A-z0-9*\.\_\-]*'

. "${HELM_SECRETS_SCRIPT_DIR}/lib/backends/_custom.sh"

_custom_backend_get_secret() {
    _type=$1
    _SECRET=$2

    if ! echo "${_SECRET}"; then
        fatal "Error while get secret!"
    fi
}
