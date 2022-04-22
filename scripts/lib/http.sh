#!/usr/bin/env sh

set -euf

download() {
    if command -v "${HELM_SECRETS_CURL_PATH:-curl}" >/dev/null; then
        "${HELM_SECRETS_CURL_PATH:-curl}" ${NETRC:+--netrc-file="${NETRC}"} -sSfL "$1"
    elif command -v "${HELM_SECRETS_WGET_PATH:-wget}" >/dev/null; then
        "${HELM_SECRETS_WGET_PATH:-wget}" -q -O- "$1"
    else
        error "Unable to detect 'curl' or 'wget'."
        return 1
    fi
}
