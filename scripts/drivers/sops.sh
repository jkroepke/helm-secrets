#!/usr/bin/env sh

_SOPS="${HELM_SECRETS_SOPS_PATH:-${HELM_SECRETS_SOPS_BIN:-sops}}"

_sops() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"
    $_SOPS "$@"
}

driver_is_file_encrypted() {
    input="${1}"

    grep -q 'sops' "${input}" && grep -q 'gcp_kms' "${input}"
}

driver_encrypt_file() {
    type="${1}"
    input="${2}"
    output="${3}"

    if [ "${input}" = "${output}" ]; then
        _sops --encrypt --input-type "${type}" --output-type "${type}" --in-place "${input}"
    else
        _sops --encrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    fi
}

driver_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        _sops --decrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    else
        _sops --decrypt --input-type "${type}" --output-type "${type}" "${input}"
    fi
}

driver_edit_file() {
    type="${1}"
    input="${2}"

    _sops --input-type yaml --output-type yaml "${input}"
}
