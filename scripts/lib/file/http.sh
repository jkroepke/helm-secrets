#!/usr/bin/env sh

set -euf

_file_http_exists() {
    _file_http_get "$@" >/dev/null
}

_file_http_get() {
    _tmp_file=$(_mktemp)
    if ! download "${1}" >"${_tmp_file}"; then
        exit 1
    fi

    printf '%s' "${_tmp_file}"
}

_file_http_put() {
    echo "Can't write to remote files!"
    exit 1
}
