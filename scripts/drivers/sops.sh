#!/usr/bin/env sh

_SOPS="${HELM_SECRETS_SOPS_PATH:-${HELM_SECRETS_SOPS_BIN:-sops}}"

_sops() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"
    $_SOPS "$@"
}

driver_is_file_encrypted() {
    input="${1}"

    grep -q 'sops' "${input}" && grep -q 'mac' "${input}" && grep -q 'version' "${input}"
}

driver_encrypt_file() {
    type="${1}"
    input="${2}"
    output="${3}"

    if _sops_windows_path_required "${input}"; then
        input="$(_convert_path "${input}")"
    fi

    if _sops_windows_path_required "${output}"; then
        output="$(_convert_path "${output}")"
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

    if _sops_windows_path_required "${input}"; then
        input="$(_convert_path "${input}")"
    fi

    # remove `aws_profile: my_profile` from the input file
    perl -i -pe 's/aws_profile: (.*)//g' "$input"

    if [ "${output}" != "" ]; then
        if _sops_windows_path_required "${output}"; then
            output="$(_convert_path "${output}")"
        fi

        _sops --decrypt --input-type "${type}" --output-type "${type}" --output "${output}" "${input}"
    else
        _sops --decrypt --input-type "${type}" --output-type "${type}" "${input}"
    fi
}

driver_edit_file() {
    type="${1}"
    input="${2}"

    if _sops_windows_path_required "${input}"; then
        input="$(_convert_path "${input}")"
    fi

    _sops --input-type yaml --output-type yaml "${input}"
}

_sops_windows_path_required() {
    if ! on_wsl; then
        return 1
    fi

    case "${_SOPS}" in
    *.exe)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}
