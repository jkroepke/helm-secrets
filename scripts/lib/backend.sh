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

_is_in_tree_secret_backend() {
    [ -f "${SCRIPT_DIR}/lib/backends/${1}.sh" ]
}

_is_allowed_secret_backend() {
    case "${ALLOWED_BACKENDS}" in
    "${1}" | "${1},"* | *",${1}" | *",${1},"*)
        true
        ;;
    *)
        false
        ;;
    esac
}

# Check if a backend may be selected via the 'backend!' prefix of a value file,
# URL or literal. That prefix comes from untrusted input (value paths, Argo CD
# Application specs), so out-of-tree backends (file paths) are only accepted
# when they are explicitly listed in HELM_SECRETS_ALLOWED_BACKENDS.
is_secret_backend() {
    if _is_in_tree_secret_backend "${1}"; then
        return 0
    fi

    [ -f "${1}" ] && _is_allowed_secret_backend "${1}"
}

load_secret_backend_override() {
    if ! _is_in_tree_secret_backend "${1}" && [ -f "${1}" ] && ! _is_allowed_secret_backend "${1}"; then
        fatal "out-of-tree secret backend '%s' is not allowed via the 'backend!' prefix. Add it to HELM_SECRETS_ALLOWED_BACKENDS to permit it." "${1}"
    fi

    load_secret_backend "${1}"
}

load_secret_backend() {
    backend="${1}"

    if [ "${backend}" = "" ]; then
        return
    fi

    if [ "${ALLOWED_BACKENDS}" != "" ] && ! _is_allowed_secret_backend "${backend}"; then
        fatal "secret backend '%s' not allowed" "${1}"
    fi

    if [ -f "${SCRIPT_DIR}/lib/backends/${backend}.sh" ]; then
        # shellcheck disable=SC2034
        SECRET_BACKEND="${backend}"
        return
    fi

    # Allow to load out of tree backends.
    if [ ! -f "${backend}" ]; then
        fatal "Can't find secret backend: %s" "${backend}"
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
