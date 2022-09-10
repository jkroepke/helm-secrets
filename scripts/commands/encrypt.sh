#!/usr/bin/env sh

set -euf

enc_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] enc [ -i ] <path to file>

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
    inline="$2"

    cd "$dir"

    if [ ! -f "${file}" ]; then
        fatal 'File does not exist: %s' "${dir}/${file}"
    fi

    if [ "${inline}" = "true" ]; then
        output="${file}"
    else
        output=""
    fi

    if backend_is_file_encrypted "${file}"; then
        fatal 'Already encrypted: %s' "${file}"
    fi

    backend_encrypt_file "yaml" "${file}" "${output}"
}

encrypt() {
    if is_help "$1"; then
        enc_usage
        return
    fi

    inline=false

    argc=$#
    j=0

    while [ $j -lt $argc ]; do
        case "$1" in
        -i)
            inline=true
            ;;
        *)
            set -- "$@" "$1"
            ;;
        esac

        shift
        j=$((j + 1))
    done

    file="$1"

    if [ ! -f "${file}" ]; then
        fatal 'File does not exist: %s' "${file}"
    fi

    encrypt_helper "${file}" "${inline}"
}
