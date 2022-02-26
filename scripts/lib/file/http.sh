#!/usr/bin/env sh

set -euf

URL_VARIABLE_EXPANSION="${HELM_SECRETS_URL_VARIABLE_EXPANSION:-false}"

_file_http_exists() {
    _file_http_get "$@" >/dev/null
}

_file_http_get() {
    set -x
    _tmp_file=$(_mktemp)

    if [ "${URL_VARIABLE_EXPANSION}" = "true" ]; then
        _url="$(printf '%s' "${1}" | expand_vars_strict)"
    else
        _url="${1}"
    fi

    if ! download "${_url}" >"${_tmp_file}"; then
        exit 1
    fi

    set +x
    printf '%s' "${_tmp_file}"
}

_file_http_put() {
    echo "Can't write to remote files!"
    exit 1
}
