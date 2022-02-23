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

    if windows_path_required "${input}"; then
        input="$(wslpath -w "${input}")"
    fi

    if windows_path_required "${output}"; then
        output="$(wslpath -w "${output}")"
    fi

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

    if windows_path_required "${input}"; then
        input="$(wslpath -w "${input}")"
    fi

    if windows_path_required "${output}"; then
        output="$(wslpath -w "${output}")"
    fi

    if [ "${output}" != "" ]; then
        _sops --decrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    else
        _sops --decrypt --input-type "${type}" --output-type "${type}" "${input}"
    fi
}

driver_edit_file() {
    type="${1}"
    input="${2}"

    if windows_path_required "${input}"; then
        input="$(wslpath -w "${input}")"
    fi

    _sops --input-type yaml --output-type yaml "${input}"
}

windows_path_required() {
    case "${_SOPS}" in
        *.exe)
            case "${1}" in
                /mnt/*)
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
}
