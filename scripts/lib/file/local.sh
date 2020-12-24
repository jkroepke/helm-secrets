#!/usr/bin/env sh

set -euf

_file_local_exists() {
    test -f "${1}"
}

_file_local_get() {
    _file_local_exists "$@" && printf '%s' "${1}"
}

_file_local_put() {
    cat - >"${1}"
}
