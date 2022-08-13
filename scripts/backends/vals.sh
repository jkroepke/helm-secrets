#!/usr/bin/env sh

_VALS="${HELM_SECRETS_VALS_PATH:-vals}"

_vals() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"

    # In case of an error, give us stderr
    # https://github.com/variantdev/vals/issues/60
    if ! $_VALS "$@" 2>/dev/null; then
        $_VALS "$@" >/dev/null
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
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        _vals eval -o yaml <"${input}" >"${output}"
    else
        _vals eval -o yaml <"${input}"
    fi
}

backend_edit_file() {
    echo "Editing files is not supported!"
    exit 1
}
