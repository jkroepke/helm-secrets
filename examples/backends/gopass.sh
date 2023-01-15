#!/usr/bin/env sh

# shellcheck disable=SC2034
_BACKEND_REGEX='!gopass [A-Za-z0-9\-\_\/]*'

# shellcheck source=scripts/lib/backends/_custom.sh
. "${SCRIPT_DIR}/lib/backends/_custom.sh"

_gopass() {
    # shellcheck disable=SC2086
    set -- ${SECRET_BACKEND_ARGS} "$@"
    gopass "$@"
}

_custom_backend_get_secret() {
    _type=$1
    _SECRET=$2

    if [ "${_type}" != "yaml" ]; then
        echo "Only decryption of yaml files are allowed!"
        exit 1
    fi

    if ! _gopass show -o "${_SECRET}"; then
        echo "Error while get secret from gopass!" >&2
        echo gopass show -o "${_SECRET}" "${SECRET_BACKEND_ARGS}" >&2
        exit 1
    fi
}
