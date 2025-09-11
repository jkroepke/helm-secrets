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

# Helper function to get backends array
_get_backends_array() {
    if [ -n "${SECRET_BACKENDS}" ]; then
        IFS=',' read -r -a backend_array <<< "${SECRET_BACKENDS}"
    else
        backend_array=("${SECRET_BACKEND}")
    fi
}

# Helper function to try each backend until one succeeds (for detection/decryption)
_try_backends_sequentially() {
    func_name="${1}"
    shift

    _get_backends_array
    for backend in "${backend_array[@]}"; do
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

    _get_backends_array
    for backend in "${backend_array[@]}"; do
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

    _get_backends_array
    _"${backend_array[0]}_${func_name}" "$@"
}

load_secret_backend() {
    backends="${1}"

    if [ "${backends}" = "" ]; then
        return
    fi

    # Split comma-separated backends into array
    # shellcheck disable=SC2034
    SECRET_BACKENDS=""

    # Handle comma-separated backends
    IFS=',' read -r -a backend_array <<< "${backends}"

    for backend in "${backend_array[@]}"; do
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

        if [ -f "${SCRIPT_DIR}/lib/backends/${backend}.sh" ]; then
            # Load built-in backend
            if [ -z "${SECRET_BACKENDS}" ]; then
                SECRET_BACKENDS="${backend}"
            else
                SECRET_BACKENDS="${SECRET_BACKENDS},${backend}"
            fi
        else
            # Allow to load out of tree backends.
            if [ ! -f "${backend}" ]; then
                fatal "Can't find secret backend: %s" "${backend}"
            fi

            # For custom backends, we load them but note that multiple custom backends aren't fully supported
            if [ -z "${SECRET_BACKENDS}" ]; then
                SECRET_BACKENDS="custom"
            else
                SECRET_BACKENDS="${SECRET_BACKENDS},custom"
            fi

            # shellcheck disable=SC2034
            HELM_SECRETS_SCRIPT_DIR="${SCRIPT_DIR}"

            # shellcheck source=tests/assets/custom-backend.sh
            . "${backend}"
        fi
    done

    # Set SECRET_BACKEND for backward compatibility (first backend)
    # shellcheck disable=SC2034
    IFS=',' read -r -a backend_array <<< "${SECRET_BACKENDS}"
    SECRET_BACKEND="${backend_array[0]}"
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
