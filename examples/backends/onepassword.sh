#!/usr/bin/env sh

#
# The 1Password CLI (https://developer.1password.com/docs/cli) allows you to get secrets
# from your vaults using secret references (https://developer.1password.com/docs/cli/secrets-reference-syntax).
# Secrets can be referenced in configuration files as described
# by the template syntax documentation (https://developer.1password.com/docs/cli/secrets-template-syntax).
#
# To use this secret backend, you need to install the 1Password CLI and sign in:
# https://developer.1password.com/docs/cli/get-started
#

set -euf

_ONEPASSWORD="${HELM_SECRETS_ONEPASSWORD_PATH:-op}"

# shellcheck disable=SC2034
# https://developer.1password.com/docs/cli/secrets-reference-syntax/#syntax-rules
_BACKEND_REGEX='op://[A-Za-z0-9\-_./ ]*'

# shellcheck source=scripts/lib/backends/_custom.sh
. "${SCRIPT_DIR}/lib/backends/_custom.sh"

_onepassword() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"
    eval "$($_ONEPASSWORD signin)"
    $_ONEPASSWORD "$@"
}

_custom_backend_get_secret() {
    if [ $# -eq 1 ]; then
        _SECRET=$1
    else
        _SECRET=$2
    fi

    _onepassword read --force "${_SECRET}"
}

_custom_backend_decrypt_file() {
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    # Templates supported by `op inject`:
    # https://developer.1password.com/docs/cli/secrets-template-syntax

    if [ "${output}" = "" ]; then
        _onepassword inject --force --in-file "${input}"
    else
        _onepassword inject --force --in-file "${input}" --out-file "${output}"
    fi
}
