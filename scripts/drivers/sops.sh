#!/usr/bin/env sh

driver_is_file_encrypted() {
    input="${1}"

    grep -q 'sops:' "${input}" && grep -q 'version:' "${input}"
}

driver_encrypt_file() {
    type="${1}"
    input="${2}"
    output="${3}"

    if [ "${input}" = "${output}" ]; then
        sops --encrypt --input-type "${type}" --output-type "${type}" --in-place "${input}"
    else
        sops --encrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    fi
}

driver_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        sops --decrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    else
        sops --decrypt --input-type "${type}" --output-type "${type}" "${input}"
    fi
}

driver_edit_file() {
    type="${1}"
    input="${2}"

    sops --input-type yaml --output-type yaml "${input}"
}
