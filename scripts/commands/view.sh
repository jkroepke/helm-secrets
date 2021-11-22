#!/usr/bin/env sh

set -euf

view_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] view <path to file>

View specified encrypted yaml file

Typical usage:
  $ helm secrets view secrets/myproject/nginx/secrets.yaml | grep basic_auth

EOF
}

view_helper() {
    file=$(echo "${1}" | envsubst) # translate env vars supplied

    if ! _file_exists "$file"; then
        error 'File does not exist: %s\n' "${file}"
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
