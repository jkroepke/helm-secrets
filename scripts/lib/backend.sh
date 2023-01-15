#!/usr/bin/env sh

set -euf

# Define the allowed secret backends
ALLOWED_BACKENDS="${HELM_SECRETS_ALLOWED_BACKENDS:-}"

# shellcheck source=scripts/lib/backends/noop.sh
. "${SCRIPT_DIR}/lib/backends/noop.sh"

# shellcheck source=scripts/lib/backends/sops.sh
. "${SCRIPT_DIR}/lib/backends/sops.sh"

# shellcheck source=scripts/lib/backends/vals.sh
. "${SCRIPT_DIR}/lib/backends/vals.sh"

load_secret_backend() {
    backend="${1}"

    if [ "${backend}" = "" ]; then
        return
    fi

    if [ "${ALLOWED_BACKENDS}" != "" ]; then
        case "${ALLOWED_BACKENDS}" in
        "${backend}" | "${backend},"* | *",${backend}" | *",${backend},"*) ;;
        *)
            fatal "secret backend '%s' not allowed" "${1}"
            ;;
        esac
    fi

    if [ -f "${SCRIPT_DIR}/lib/backends/${1}.sh" ]; then
        # shellcheck disable=SC2034
        SECRET_BACKEND="${1}"
        return
    fi

    # Allow to load out of tree backends.
    if [ ! -f "${1}" ]; then
        fatal "Can't find secret backend: %s" "${1}"
    fi

    # shellcheck disable=SC2034
    SECRET_BACKEND="custom"

    # shellcheck disable=SC2034
    HELM_SECRETS_SCRIPT_DIR="${SCRIPT_DIR}"

    # shellcheck source=tests/assets/custom-backend.sh
    . "${1}"
}

backend_is_file_encrypted() {
    _"${SECRET_BACKEND}"_backend_is_file_encrypted "$@"
}

backend_is_encrypted() {
    _"${SECRET_BACKEND}"_backend_is_encrypted "$@"
}

backend_encrypt_file() {
    _"${SECRET_BACKEND}"_backend_encrypt_file "$@"
}

backend_decrypt_file() {
    _"${SECRET_BACKEND}"_backend_decrypt_file "$@"
}

backend_decrypt_literal() {
    _"${SECRET_BACKEND}"_backend_decrypt_literal "$@"
}

backend_edit_file() {
    _"${SECRET_BACKEND}"_backend_edit_file "$@"
}
