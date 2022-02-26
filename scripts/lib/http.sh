#!/usr/bin/env sh

set -euf

download() {
    if command -v curl >/dev/null; then
        curl ${NETRC:+--netrc-file="${NETRC}"} -sSfL "$1"
    elif command -v curl.exe >/dev/null; then
        curl.exe ${NETRC:+--netrc-file="${NETRC}"} -sSfL "$1"
    elif command -v wget >/dev/null; then
        wget -q -O- "$1"
    else
        return 1
    fi
}
