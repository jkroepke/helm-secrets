#!/usr/bin/env sh

_envsubst() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"
    envsubst "$@"
}

driver_is_file_encrypted() {
    input="${1}"

    grep -q '\$' "${input}"
}

driver_encrypt_file() {
    echo "Encrypting files with envsubst driver is not supported!"
    exit 1
}

driver_decrypt_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        _envsubst <"${input}" >"${output}"
    else
        _envsubst <"${input}"
    fi
}

driver_edit_file() {
    echo "Editing files with envsubst driver is not supported!"
    exit 1
}
