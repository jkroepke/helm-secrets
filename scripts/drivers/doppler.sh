#!/usr/bin/env sh

_DOPPLER="${HELM_SECRETS_VAULT_PATH:-doppler}"

# shellcheck disable=SC2034
_DRIVER_REGEX='!doppler [a-z0-9_-]*\#.*\#[A-Z0-9_]*'

# shellcheck source=scripts//drivers/_custom.sh
. "${SCRIPT_DIR}/drivers/_custom.sh"

_doppler() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"
    $_DOPPLER "$@"
}

_custom_driver_get_secret() {
    _SECRET=$2

    # Tokenize
    IFS="#"
    # shellcheck disable=SC2086
    set -- $_SECRET
    project=$1
    config=$2
    secret=$3

    _doppler secrets get -p "${project}" -c "${config}" "${secret}" --plain || exit 1
}
