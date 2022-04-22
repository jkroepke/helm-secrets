#!/usr/bin/env sh

set -euf

VALUES_ALLOW_SYMLINKS="${HELM_SECRETS_VALUES_ALLOW_SYMLINKS:-true}"
VALUES_ALLOW_ABSOLUTE_PATH="${HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH:-true}"
VALUES_ALLOW_PATH_TRAVERSAL="${HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL:-true}"

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

    if [ "${file_type}" = "local" ]; then
        if [ "${VALUES_ALLOW_SYMLINKS}" = "false" ] && [ -L "${1}" ]; then
            fatal "Values file '%s' is a symlink. Symlinks are not allowed." "${1}"
        fi

        if [ "${VALUES_ALLOW_ABSOLUTE_PATH}" = "false" ]; then
            case "${1}" in
            /*) fatal "Values filepath '%s' is an absolute path. Absolute paths are not allowed." "${1}" ;;
            \\*) fatal "Values filepath '%s' is an absolute path. Absolute paths are not allowed." "${1}" ;;
            *:*) fatal "Values filepath '%s' is an absolute path. Absolute paths are not allowed." "${1}" ;;
            esac
        fi

        if [ "${VALUES_ALLOW_PATH_TRAVERSAL}" = "false" ]; then
            case "${1}" in
            *../*) fatal "Values filepath '%s' contains '..'. Path traversal is not allowed." "${1}" ;;
            */..*) fatal "Values filepath '%s' contains '..'. Path traversal is not allowed." "${1}" ;;
            esac
        fi
    fi

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
