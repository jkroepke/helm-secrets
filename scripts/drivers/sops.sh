#!/usr/bin/env sh

_SOPS="${HELM_SECRETS_SOPS_BIN:-sops}"

driver_is_file_encrypted() {
    input="${1}"

    grep -q 'sops:' "${input}" && grep -q 'version:' "${input}"
}

driver_encrypt_file() {
    type="${1}"
    input="${2}"
    output="${3}"
    suffix="${4:-}"

    if [ "${input}" = "${output}" ]; then
        $_SOPS --encrypt --encrypted-suffix="${suffix}" --input-type "${type}" --output-type "${type}" --in-place "${input}"
    else
        $_SOPS --encrypt --encrypted-suffix="${suffix}" --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    fi
}

driver_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        $_SOPS --decrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    else
        $_SOPS --decrypt --input-type "${type}" --output-type "${type}" "${input}"
    fi
}

driver_edit_file() {
    type="${1}"
    input="${2}"

    $_SOPS --input-type yaml --output-type yaml "${input}"
}
