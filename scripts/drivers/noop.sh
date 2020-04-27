#!/usr/bin/env sh

driver_is_file_encrypted() {
    true
}

driver_encrypt_file() {
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

driver_decrypt_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        cat "${input}" >"${output}"
    else
        cat "${input}"
    fi
}

driver_edit_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"

    "${EDITOR:-vi}" "${input}"
}
