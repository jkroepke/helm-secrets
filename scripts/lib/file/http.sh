#!/usr/bin/env sh

set -euf

URL_VARIABLE_EXPANSION="${HELM_SECRETS_URL_VARIABLE_EXPANSION:-false}"

_file_http_exists() {
    _file_http_get "$@" >/dev/null
}

_file_http_get() {
    if [ "${URL_VARIABLE_EXPANSION}" = "true" ]; then
        _url="$(printf '%s' "${1}" | expand_vars_strict)"
    else
        _url="${1}"
    fi

    _tmp_file="$(_mktemp).${_url##*.}"

    if ! download "${_url}" >"${_tmp_file}"; then
        fatal "Error while download url %s" "${1}"
    fi

    printf '%s' "${_tmp_file}"
}

_file_http_put() {
    fatal "Can't write to remote files!"
}
