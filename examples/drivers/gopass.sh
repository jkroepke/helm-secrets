#!/usr/bin/env sh

# shellcheck disable=SC2034
_DRIVER_REGEX='!gopass [A-Za-z0-9\-\_\/]*'

# shellcheck source=scripts//drivers/_custom.sh
. "${SCRIPT_DIR}/drivers/_custom.sh"

_gopass() {
    # shellcheck disable=SC2086
    set -- ${SECRET_DRIVER_ARGS} "$@"
    gopass "$@"
}

_custom_driver_get_secret() {
    _type=$1
    _SECRET=$2

    if [ "${_type}" != "yaml" ]; then
        echo "Only decryption of yaml files are allowed!"
        exit 1
    fi

    if ! _gopass show -o "${_SECRET}"; then
        echo "Error while get secret from gopass!" >&2
        echo gopass show -o "${_SECRET}" "${SECRET_DRIVER_ARGS}" >&2
        exit 1
    fi
}
