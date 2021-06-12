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
        error '[helm-secrets] Error while decrypting file: %s\n' "${file}"
    fi
}

dec() {
    if is_help "$1"; then
        dec_usage
        return
    fi

    file="$1"

    if [ "${QUIET}" = "false" ]; then
        printf '[helm-secrets] Decrypting %s\n' "${file}"
    fi

    if ! encrypted_file_path=$(_file_get "${file}"); then
        error '[helm-secrets] File does not exist: %s\n' "${file}"
    fi

    if ! decrypt_helper "${encrypted_file_path}"; then
        error '[helm-secrets] File is not encrypted: %s\n' "${file}"
    fi

    if [ "${OUTPUT_DECRYPTED_FILE_PATH}" = "true" ]; then
        _file_dec_name "${encrypted_file_path}"
    fi
}
