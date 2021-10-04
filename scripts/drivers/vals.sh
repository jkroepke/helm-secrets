#!/usr/bin/env sh

_VALS="${HELM_SECRETS_VALS_PATH:-vals}"

_vals() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"

    # In case of an error, give us stderr
    # https://github.com/variantdev/vals/issues/60
    if ! $_VALS "$@" 2>/dev/null; then
        $_VALS "$@" >/dev/null
    fi
}

driver_is_file_encrypted() {
    input="${1}"

    grep -q 'ref+' "${input}"
}

driver_encrypt_file() {
    echo "Encrypting files is not supported!"
    exit 1
}

driver_decrypt_file() {
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        _vals eval -f "${input}" -o yaml >"${output}"
    else
        _vals eval -f "${input}" -o yaml
    fi
}

driver_edit_file() {
    echo "Editing files is not supported!"
    exit 1
}
