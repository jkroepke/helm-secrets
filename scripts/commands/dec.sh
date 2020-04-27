#!/usr/bin/env sh

set -eu

dec_usage() {
    cat <<EOF
helm secrets dec [ --driver <driver> | -d <driver> ] <path to file>

Decrypt secrets

It uses your gpg credentials to decrypt previously encrypted .yaml file.
Produces ${DEC_SUFFIX} file.

You can use plain sops to decrypt specific files - https://github.com/mozilla/sops

Typical usage:
  $ helm secrets dec secrets/myproject/secrets.yaml
  $ vim secrets/myproject/secrets.yaml.dec

EOF
}

decrypt_helper() {
    file="${1}"

    if [ ! -f "$file" ]; then
        printf 'File does not exist: %s\n' "${file}"
        exit 1
    fi

    if ! driver_is_file_encrypted "${file}"; then
        return 1
    fi

    file_dec="$(file_dec_name "${file}")"

    if ! driver_decrypt_file "yaml" "${file}" "${file_dec}"; then
        printf 'Error while decrypting file: %s\n' "${file}"
        exit 1
    fi

    return 0
}

dec() {
    if is_help "$1"; then
        dec_usage
        return
    fi

    file="$1"

    if [ ! -f "${file}" ]; then
        printf 'File does not exist: %s\n' "${file}"
        exit 1
    else
        printf 'Decrypting %s\n' "${file}"
        decrypt_helper "${file}"
    fi
}
