#!/usr/bin/env sh

if [ "${QUIET}" = "false" ]; then
    log 'DEPRECATED: Envsubst backend is going to be remove in the next major version. Use vals backend instead.'
fi

_envsubst() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"
    envsubst "$@"
}

_custom_backend_is_file_encrypted() {
    input="${1}"

    grep -q '\$' "${input}"
}

_custom_backend_encrypt_file() {
    echo "Encrypting files with envsubst backend is not supported!"
    exit 1
}

_custom_backend_decrypt_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${output}" != "" ]; then
        _envsubst <"${input}" >"${output}"
    else
        _envsubst <"${input}"
    fi
}

_custom_backend_edit_file() {
    echo "Editing files with envsubst backend is not supported!"
    exit 1
}
