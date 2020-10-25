#!/usr/bin/env sh

_file_http_exists() {
    _file_http_get "$@" >/dev/null
}

_file_http_get() {
    _tmp_file=$(mktemp)
    download "${1}" >"${_tmp_file}"
    printf '%s' "${_tmp_file}"
}

_file_http_put() {
    echo "Can't write to remote files!"
    exit 1
}
