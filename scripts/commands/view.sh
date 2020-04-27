#!/usr/bin/env sh

set -eu

view_usage() {
    cat <<EOF
helm secrets view [ --driver <driver> | -d <driver> ] <path to file>

View specified secrets[.*].yaml file

Typical usage:
  $ helm secrets view secrets/myproject/nginx/secrets.yaml | grep basic_auth

EOF
}

view_helper() {
    file="$1"

    if [ ! -f "${file}" ]; then
        printf 'File does not exist: %s\n' "${file}"
        exit 1
    fi

    driver_decrypt_file "yaml" "${file}"
}

view() {
    if is_help "$1"; then
        view_usage
        return
    fi

    view_helper "$1"
}
