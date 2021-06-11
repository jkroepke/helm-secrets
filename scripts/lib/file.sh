#!/usr/bin/env sh

set -euf

# shellcheck source=scripts/lib/file/local.sh
. "${SCRIPT_DIR}/lib/file/local.sh"

# shellcheck source=scripts/lib/file/http.sh
. "${SCRIPT_DIR}/lib/file/http.sh"

# shellcheck source=scripts/lib/file/custom.sh
. "${SCRIPT_DIR}/lib/file/custom.sh"

_file_get_protocol() {
    case "$1" in
    http*)
        echo "http"
        ;;
    *://*)
        echo "custom"
        ;;
    *)
        echo "local"
        ;;
    esac
}

_file_exists() {
    file_type=$(_file_get_protocol "${1}")

    _file_"${file_type}"_exists "$@"
}

_file_get() {
    file_type=$(_file_get_protocol "${1}")

    _file_"${file_type}"_get "$@"
}

_file_put() {
    file_type=$(_file_get_protocol "${1}")

    _file_"${file_type}"_put "$@"
}

_file_dec_name() {
    _basename="$(basename "${1}")"

    if [ "${DEC_DIR}" != "" ]; then
        printf '%s/%s%s%s' "${DEC_DIR}" "${DEC_PREFIX}" "${_basename}" "${DEC_SUFFIX}"
    elif [ "${1}" != "${_basename}" ]; then
        printf '%s/%s%s%s' "$(dirname "${1}")" "${DEC_PREFIX}" "${_basename}" "${DEC_SUFFIX}"
    else
        printf '%s%s%s' "${DEC_PREFIX}" "${_basename}" "${DEC_SUFFIX}"
    fi
}
