#!/usr/bin/env sh

set -euf

_VALS="${HELM_SECRETS_VALS_PATH:-vals}"

_vals() {
    stdin=$(cat /dev/stdin)
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"

    # In case of an error, give us stderr
    # https://github.com/variantdev/vals/issues/60
    if ! printf '%s' "$stdin" | $_VALS "$@" 2>/dev/null; then
        log 'vals error:'
        printf '%s' "$stdin" | $_VALS "$@" >/dev/null
    fi
}

backend_is_file_encrypted() {
    backend_is_encrypted <"${1}"
}

backend_is_encrypted() {
    stdin=$(cat /dev/stdin)

    [ "${stdin#*ref+}" != "$stdin" ]
}

backend_encrypt_file() {
    fatal "Encrypting files is not supported!"
}

backend_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${type}" = "auto" ]; then
        type=$(_vals_get_type "${input}")
    fi

    if [ "${input}" = "${output}" ]; then
        fatal "vals: inline decryption is not supported!"
    elif [ "${output}" = "" ]; then
        _vals eval -o "${type}" <"${input}"
    else
        _vals eval -o "${type}" <"${input}" >"${output}"
    fi
}

backend_decrypt_literal() {
    if printf '%s' "${1}" | backend_is_encrypted; then
        if ! literal_value=$(printf '"": %s' "${1}" | _vals env -f -); then
            return 1
        fi

        printf '%s' "${literal_value#*=}"
    else
        printf '%s' "${1}"
    fi
}

backend_edit_file() {
    fatal "vals: Editing files is not supported!"
}

_vals_get_type() {
    file_type=$(_file_get_extension "${1}")
    if [ "${file_type}" = "json" ]; then
        echo "json"
    else
        echo "yaml"
    fi
}
