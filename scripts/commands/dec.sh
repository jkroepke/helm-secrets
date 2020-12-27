#!/usr/bin/env sh

set -euf

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
    encrypted_file_path="${1}"

    if ! driver_is_file_encrypted "${encrypted_file_path}"; then
        return 1
    fi

    encrypted_file_dec="$(_file_dec_name "${encrypted_file_path}")"

    if ! driver_decrypt_file "yaml" "${encrypted_file_path}" "${encrypted_file_dec}"; then
        printf '[helm-secrets] Error while decrypting file: %s\n' "${file}"
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

    printf '[helm-secrets] Decrypting %s\n' "${file}"

    if ! encrypted_file_path=$(_file_get "${file}"); then
        printf '[helm-secrets] File does not exist: %s\n' "${file}"
        exit 1
    fi

    if ! decrypt_helper "${encrypted_file_path}"; then
        printf '[helm-secrets] File is not encrypted: %s\n' "${file}"
        exit 1
    fi
}
