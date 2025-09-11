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

is_secret_backend() {
    [ -f "${SCRIPT_DIR}/lib/backends/${1}.sh" ] || [ -f "${1}" ]
}

# Helper function to get backends as a space-separated string
_get_backends() {
    if [ -n "${SECRET_BACKENDS}" ]; then
        # Convert comma-separated to space-separated
        printf '%s' "${SECRET_BACKENDS}" | sed 's/,/ /g'
    else
        printf '%s' "${SECRET_BACKEND}"
    fi
}

# Helper function to try each backend until one succeeds (for detection/decryption)
_try_backends_sequentially() {
    func_name="${1}"
    shift

    for backend in $(_get_backends); do
        if _"${backend}_${func_name}" "$@"; then
            return 0
        fi
    done
    return 1
}

# Helper function to try each backend until one succeeds with result capture (for literal decryption)
_try_backends_sequentially_with_result() {
    func_name="${1}"
    shift

    for backend in $(_get_backends); do
        if result=$(_"${backend}_${func_name}" "$@" 2>/dev/null); then
            printf '%s' "${result}"
            return 0
        fi
    done
    return 1
}

# Helper function to use first backend (for encryption/editing)
_use_first_backend() {
    func_name="${1}"
    shift

    # Get the first backend
    for backend in $(_get_backends); do
        _"${backend}_${func_name}" "$@"
        return
    done
}

load_secret_backend() {
    backends="${1}"

    if [ "${backends}" = "" ]; then
        return
    fi

    # To store the processed, comma-separated list of backends
    processed_backends=""

    # Handle comma-separated backends
    old_IFS="${IFS:-$' \t\n'}"
    IFS=','
    set -- $backends
    IFS="${old_IFS}"
    for backend; do
        # Trim whitespace
        backend=$(printf '%s' "${backend}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [ "${backend}" = "" ]; then
            continue
        fi

        if [ "${ALLOWED_BACKENDS}" != "" ]; then
            case "${ALLOWED_BACKENDS}" in
            "${backend}" | "${backend},"* | *",${backend}" | *",${backend},"*) ;;
            *)
                fatal "secret backend '%s' not allowed" "${backend}"
                ;;
            esac
        fi

        # Determine the backend name to be added
        backend_to_add="${backend}"
        if [ -f "${SCRIPT_DIR}/lib/backends/${backend}.sh" ]; then
            # This is a built-in backend
            :
        else
            # This is a custom backend
            if [ ! -f "${backend}" ]; then
                fatal "Can't find secret backend: %s" "${backend}"
            fi
            backend_to_add="custom"

            # shellcheck disable=SC2034
            HELM_SECRETS_SCRIPT_DIR="${SCRIPT_DIR}"
            # shellcheck source=tests/assets/custom-backend.sh
            . "${backend}"
        fi

        if [ -z "${processed_backends}" ]; then
            processed_backends="${backend_to_add}"
        else
            processed_backends="${processed_backends},${backend_to_add}"
        fi
    done

    # Set SECRET_BACKENDS to the processed list
    # shellcheck disable=SC2034
    SECRET_BACKENDS="${processed_backends}"

    # Set SECRET_BACKEND for backward compatibility (first backend)
    # shellcheck disable=SC2034
    if [ -n "${SECRET_BACKENDS}" ]; then
        old_IFS="${IFS:-$' \t\n'}"
        IFS=','
        set -- $SECRET_BACKENDS
        IFS="${old_IFS}"
        SECRET_BACKEND="${1}"
    else
        SECRET_BACKEND=""
    fi
}

backend_is_file_encrypted() {
    _try_backends_sequentially "backend_is_file_encrypted" "$@"
}

backend_is_encrypted() {
    _try_backends_sequentially "backend_is_encrypted" "$@"
}

backend_encrypt_file() {
    _use_first_backend "backend_encrypt_file" "$@"
}

backend_decrypt_file() {
    _try_backends_sequentially "backend_decrypt_file" "$@" 2>/dev/null
}

backend_decrypt_literal() {
    _try_backends_sequentially_with_result "backend_decrypt_literal" "$@"
}

backend_edit_file() {
    _use_first_backend "backend_edit_file" "$@"
}
