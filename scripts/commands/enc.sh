#!/usr/bin/env sh

set -euf

enc_usage() {
    cat <<EOF
helm secrets enc [ --driver <driver> | -d <driver> ] <path to file>

Encrypt secrets

It uses your gpg credentials to encrypt .yaml file. If the file is already
encrypted, look for a decrypted file and encrypt that to .yaml.
This allows you to first decrypt the file, edit it, then encrypt it again.

You can use plain sops to encrypt - https://github.com/mozilla/sops

Example:
  $ helm secrets enc <SECRET_FILE_PATH>
  $ git add <SECRET_FILE_PATH>
  $ git commit
  $ git push

EOF
}

encrypt_helper() {
    dir=$(dirname "$1")
    file=$(basename "$1")

    cd "$dir"

    if [ ! -f "${file}" ]; then
        error 'File does not exist: %s\n' "${dir}/${file}"
    fi
    file_dec="$(_file_dec_name "${file}")"

    if [ ! -f "${file_dec}" ]; then
        file_dec="${file}"
    fi

    if driver_is_file_encrypted "${file_dec}"; then
        error "Already encrypted: %s\n" "${file_dec}"
    fi

    driver_encrypt_file "yaml" "${file_dec}" "${file}"

    if [ "${file}" = "${file_dec}" ]; then
        printf 'Encrypted %s\n' "${file_dec}"
    else
        printf 'Encrypted %s to %s\n' "${file_dec}" "${file}"
    fi
}

enc() {
    if is_help "$1"; then
        enc_usage
        return
    fi

    file="$1"

    if [ ! -f "${file}" ]; then
        error 'File does not exist: %s\n' "${file}"
    fi

    printf 'Encrypting %s\n' "${file}"
    encrypt_helper "${file}"
}
