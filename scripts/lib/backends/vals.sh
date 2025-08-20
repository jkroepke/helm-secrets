#!/usr/bin/env sh

set -euf

_VALS="${HELM_SECRETS_VALS_PATH:-vals}"

# Preprocess ref+gcpsecrets://mysecret to ref+gcpsecrets://${HELM_SECRETS_GCP_PROJECT}/mysecret
_vals_preprocess_gcp_secrets() {
    input_content="${1}"

    # Check if we need to preprocess and have HELM_SECRETS_GCP_PROJECT set
    if printf '%s' "${input_content}" | grep -q 'ref+gcpsecrets://[^/[:space:]]*[[:space:]]\|ref+gcpsecrets://[^/[:space:]]*$'; then
        if [ -z "${HELM_SECRETS_GCP_PROJECT:-}" ]; then
            fatal "HELM_SECRETS_GCP_PROJECT environment variable must be set when using ref+gcpsecrets://mysecret pattern"
        fi

        # Replace patterns that don't have a project path (no / after ://)
        # This regex matches ref+gcpsecrets:// followed by non-slash/non-space characters
        # and ensures we only match those that don't already have a slash in the path part
        printf '%s' "${input_content}" | sed '
            s|ref+gcpsecrets://\([^/[:space:]]*\)\([[:space:]]\)|ref+gcpsecrets://'"${HELM_SECRETS_GCP_PROJECT}"'/\1\2|g
            s|ref+gcpsecrets://\([^/[:space:]]*\)$|ref+gcpsecrets://'"${HELM_SECRETS_GCP_PROJECT}"'/\1|g
        '
    else
        printf '%s' "${input_content}"
    fi
}

_vals() {
    # shellcheck disable=SC2086
    set -- "$@" ${SECRET_BACKEND_ARGS}

    # In case of an error, give us stderr
    # https://github.com/variantdev/vals/issues/60
    # Store stderr in a var - https://stackoverflow.com/a/52587939
    if ! { error=$({ $_VALS "$@" 1>&3; } 2>&1); } 3>&1; then
        fatal "vals error: $error"
    fi
}

_vals_backend_is_file_encrypted() {
    _vals_backend_is_encrypted <"${1}"
}

_vals_backend_is_encrypted() {
    grep -q 'ref+' -
}

_vals_backend_encrypt_file() {
    fatal "Encrypting files is not supported!"
}

_vals_backend_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${type}" = "auto" ]; then
        type=$(_vals_get_type "${input}")
    fi

    if [ "${input}" = "${output}" ]; then
        fatal "vals: inline decryption is not supported!"
    elif [ "${input}" = "-" ]; then
        temp_content=$(cat)
        _vals_preprocess_gcp_secrets "${temp_content}" | _vals eval -o "${type}"
    elif [ "${output}" = "" ]; then
        _vals_preprocess_gcp_secrets "$(cat "${input}")" | _vals eval -o "${type}"
    else
        _vals_preprocess_gcp_secrets "$(cat "${input}")" | _vals eval -o "${type}" >"${output}"
    fi
}

_vals_backend_decrypt_literal() {
    input_literal="${1}"

    # Preprocess the literal for GCP secrets
    preprocessed_literal="$(_vals_preprocess_gcp_secrets "${input_literal}")"

    if printf '%s' "${preprocessed_literal}" | _vals_backend_is_encrypted; then
        if ! value="$(_vals get "${preprocessed_literal}")"; then
            return 1
        fi

        printf '%s' "${value}"
    else
        printf '%s' "${preprocessed_literal}"
    fi
}

_vals_backend_edit_file() {
    fatal "vals: Editing files is not supported!"
}

_vals_get_type() {
    file_type=$(_file_get_extension "${1}")
    if [ "${file_type}" = "json" ]; then
        echo "json"
    else
        echo "yaml"
    fi
}
