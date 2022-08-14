#!/usr/bin/env sh

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
    input="${1}"

    grep -q 'ref+' "${input}"
}

backend_encrypt_file() {
    echo "Encrypting files is not supported!"
    exit 1
}

backend_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${type}" = "auto" ]; then
        type=$(_vals_get_type "${input}")
    fi

    if [ "${output}" != "" ]; then
        _vals eval -o "${type}" <"${input}" >"${output}"
    else
        _vals eval -o "${type}" <"${input}"
    fi
}

backend_edit_file() {
    echo "Editing files is not supported!"
    exit 1
}

_vals_get_type() {
    case "${1}" in
    *.json | *.json.*)
        echo "json"
        ;;
    *)
        echo "yaml"
        ;;
    esac
}
