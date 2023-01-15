#!/usr/bin/env sh

if [ "${QUIET}" = "false" ]; then
    log 'DEPRECATED: doppler backend is going to be removed in the next major version.'
fi

_DOPPLER="${HELM_SECRETS_VAULT_PATH:-doppler}"

# shellcheck disable=SC2034
_BACKEND_REGEX='!doppler [a-z0-9_-]*\#.*\#[A-Z0-9_]*'

# shellcheck source=scripts/lib/backends/_custom.sh
. "${SCRIPT_DIR}/lib/backends/_custom.sh"

_doppler() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"
    $_DOPPLER "$@"
}

_custom_backend_get_secret() {
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
