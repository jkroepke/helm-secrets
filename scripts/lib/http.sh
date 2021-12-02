#!/usr/bin/env sh

set -euf

download() {
    if command -v curl >/dev/null; then
        curl --netrc-optional --netrc-file "${NETRC:-"~/.netrc"}" -sSfL "$1"
    elif command -v wget >/dev/null; then
        wget -q -O- "$1"
    else
        return 1
    fi
}
