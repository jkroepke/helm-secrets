#!/usr/bin/env sh

_SOPS="${HELM_SECRETS_SOPS_PATH:-${HELM_SECRETS_SOPS_BIN:-sops}}"

_sops() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"
    $_SOPS "$@"
}

backend_is_file_encrypted() {
    input="${1}"

    grep -q 'sops' "${input}" && grep -q 'mac' "${input}" && grep -q 'version' "${input}"
}

backend_encrypt_file() {
    type="${1}"
    input="${2}"
    output="${3}"

    if [ "${input}" = "${output}" ]; then
        _sops --encrypt --input-type "${type}" --output-type "${type}" --in-place "$(_sops_winpath "${input}")"
    else
        _sops --encrypt --input-type "${type}" --output-type "${type}" --output "$(_sops_winpath "${output}")" "$(_sops_winpath "${input}")"
    fi
}

backend_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        _sops --decrypt --input-type "${type}" --output-type "${type}" --output "$(_sops_winpath "${output}")" "$(_sops_winpath "${input}")"
    else
        _sops --decrypt --input-type "${type}" --output-type "${type}" "$(_sops_winpath "${input}")"
    fi
}

backend_edit_file() {
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
