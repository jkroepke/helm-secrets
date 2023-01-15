#!/usr/bin/env sh

_SOPS="${HELM_SECRETS_SOPS_PATH:-${HELM_SECRETS_SOPS_BIN:-sops}}"

_sops() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"
    $_SOPS "$@"
}

_sops_backend_is_file_encrypted() {
    _sops_backend_is_encrypted <"${1}"
}

_sops_backend_is_encrypted() {
    grep -q 'mac.*,type:str]' -
}

_sops_backend_encrypt_file() {
    type="${1}"
    input="${2}"
    output="${3}"

    if [ "${type}" = "auto" ]; then
        type=$(_sops_enc_get_type "${input}")
    fi

    if [ "${input}" = "${output}" ]; then
        _sops --encrypt --input-type "${type}" --output-type "${type}" --in-place "$(_sops_winpath "${input}")"
    elif [ "${output}" = "" ]; then
        _sops --encrypt --input-type "${type}" --output-type "${type}" "$(_sops_winpath "${input}")"
    else
        _sops --encrypt --input-type "${type}" --output-type "${type}" --output "$(_sops_winpath "${output}")" "$(_sops_winpath "${input}")"
    fi
}

_sops_backend_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${type}" = "auto" ]; then
        type=$(_sops_dec_get_type "${input}")
    fi

    if [ "${input}" = "${output}" ]; then
        _sops --decrypt --input-type "${type}" --output-type "${type}" --in-place "$(_sops_winpath "${input}")"
    elif [ "${output}" = "" ]; then
        _sops --decrypt --input-type "${type}" --output-type "${type}" "$(_sops_winpath "${input}")"
    else
        _sops --decrypt --input-type "${type}" --output-type "${type}" --output "$(_sops_winpath "${output}")" "$(_sops_winpath "${input}")"
    fi
}

_sops_backend_decrypt_literal() {
    if printf '%s' "${1}" | _sops_backend_is_encrypted; then
        printf '%s' "${1}" | _sops --decrypt --input-type 'json' --output-type 'json' /dev/stdin
    else
        printf '%s' "${1}"
    fi
}

_sops_backend_edit_file() {
    type="${1}"
    input="${2}"

    _sops --input-type yaml --output-type yaml "$(_sops_winpath "${input}")"
}

_sops_winpath() {
    if on_cygwin; then
        _winpath "$@"
    elif on_wsl; then
        case "${_SOPS}" in
        *.exe) _winpath "$@" ;;
        *) printf '%s' "$@" ;;
        esac
    else
        printf '%s' "$@"
    fi
}

_sops_dec_get_type() {
    if grep -xq 'sops:\s*' "${1}"; then
        echo 'yaml'
    elif grep -q '"data": "ENC' "${1}"; then
        echo 'binary'
    else
        echo 'json'
    fi
}

_sops_enc_get_type() {
    file_type=$(_file_get_extension "${1}")
    if [ "${file_type}" = "other" ]; then
        echo 'binary'
    else
        echo "${file_type}"
    fi
}
