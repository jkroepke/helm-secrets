#!/usr/bin/env sh

set -euf

dec_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] dec <path to file>

Decrypt secrets

It uses your gpg credentials to decrypt previously encrypted values file.

You can use plain sops to decrypt specific files - https://github.com/mozilla/sops

Typical usage:
  $ helm secrets dec secrets/project/secrets.yaml
  $ vim secrets/project/secrets.yaml.dec

EOF
}

decrypt_helper() {
    encrypted_file_path="${1}"

    if ! driver_is_file_encrypted "${encrypted_file_path}"; then
        return 1
    fi

    encrypted_file_dec="$(_file_dec_name "${encrypted_file_path}")"

    if ! driver_decrypt_file "yaml" "${encrypted_file_path}" "${encrypted_file_dec}"; then
        rm -rf "${encrypted_file_dec}"
        fatal 'Error while decrypting file: %s' "${file}"
    fi

    return 0
}

dec() {
    if is_help "$1"; then
        dec_usage
        return
    fi

    file="$1"

    if [ "${QUIET}" = "false" ]; then
        log 'Decrypting %s' "${file}"
    fi

    if ! encrypted_file_path=$(_file_get "${file}"); then
        fatal 'File does not exist: %s' "${file}"
    fi

    if ! decrypt_helper "${encrypted_file_path}"; then
        fatal 'File is not encrypted: %s' "${file}"
    fi

    if [ "${OUTPUT_DECRYPTED_FILE_PATH}" = "true" ]; then
        _file_dec_name "${encrypted_file_path}"
    fi
}
