#!/usr/bin/env sh

backend_is_file_encrypted() {
    true
}

backend_encrypt_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"
    output="${3}"

    if [ "${input}" = "${output}" ]; then
        # encrypt in-place
        true
    else
        cat "${input}" >"${output}"
    fi
}

backend_decrypt_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${input}" = "${output}" ]; then
        :
    elif [ "${output}" = "" ]; then
        cat "${input}"
    else
        cat "${input}" >"${output}"
    fi
}

backend_decrypt_literal() {
    printf '%s' "${1}"
}

backend_edit_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"

    "${EDITOR:-vi}" "${input}"
}
