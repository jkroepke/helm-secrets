#!/usr/bin/env sh

set -euf

view_usage() {
    cat <<EOF
helm secrets view [ --driver <driver> | -d <driver> ] <path to file>

View specified encrypted yaml file

Typical usage:
  $ helm secrets view secrets/myproject/nginx/secrets.yaml | grep basic_auth

EOF
}

view_helper() {
    file="$1"

    if ! _file_exists "$file"; then
        printf 'File does not exist: %s\n' "${file}"
        exit 1
    fi

    real_file=$(_file_get "${file}")

    if driver_is_file_encrypted "${real_file}"; then
        driver_decrypt_file "yaml" "${real_file}"
    else
        cat "${real_file}"
    fi
}

view() {
    if is_help "$1"; then
        view_usage
        return
    fi

    view_helper "$1"
}
