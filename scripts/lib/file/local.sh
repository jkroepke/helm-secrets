#!/usr/bin/env sh

set -euf

_file_local_exists() {
    test -f "${1}"
}

_file_local_get() {
    if ! _file_local_exists "$@"; then
        exit 1
    fi

    printf '%s' "${1}"
}

_file_local_put() {
    cat - >"${1}"
}
