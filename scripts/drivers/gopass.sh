#!/usr/bin/env sh
set -e

_VAULT_REGEX='!vault [A-Za-z0-9\-\_\/]*'

driver_is_file_encrypted() {
    input="${1}"

    grep -q -e "${_VAULT_REGEX}" "${input}"
}

driver_encrypt_file() {
    echo "Encrypting files via gopass driver is not supported!"
    exit 1
}

driver_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${type}" != "yaml" ]; then
        echo "Only decryption of yaml files are allowed!"
        exit 1
    fi

    output_tmp="$(mktemp)"

    while IFS= read -r EXPRESSION; do
        SUFFIX=${EXPRESSION%:*}
        SECRET_PATH=$(echo "${EXPRESSION#*:}" | sed 's/!vault *//' | tr -d '[:space:]')
        if [ -n "$SECRET_PATH" ]; then
            SECRET=$(gopass show -o "${SECRET_PATH}")
            echo "${SUFFIX}"": ""${SECRET}" >>"${output_tmp}"
        elif [ -n "$SUFFIX" ]; then
            echo "${SUFFIX}"": " >>"${output_tmp}"
        fi
    done <"${input}"

    if [ "${output}" = "" ]; then
        cat "${output_tmp}"
    else
        cat "${output_tmp}" >"${output}"
    fi
}

driver_edit_file() {
    echo "Editing files via gopass driver is not supported!"
    exit 1
}
