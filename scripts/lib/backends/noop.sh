#!/usr/bin/env sh

_noop_backend_is_file_encrypted() {
    true
}

_noop_backend_is_encrypted() {
    true
}

_noop_backend_edit_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"

    "${EDITOR:-vi}" "${input}"
}

_noop_backend_encrypt_file() {
    fatal "Encrypting files is not supported!"
}

_noop_backend_decrypt_file() {
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${input}" = "${output}" ]; then
        :
    elif [ "${input}" = "-" ]; then
        cat
    elif [ "${output}" = "" ]; then
        cat <"${input}"
    else
        cp "${input}" "${output}"
    fi
}
