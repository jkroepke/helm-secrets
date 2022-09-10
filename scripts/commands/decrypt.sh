#!/usr/bin/env sh

set -euf

dec_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] dec [ -i ] [ --terraform ] <path to file>

Decrypt secrets

It uses your gpg credentials to decrypt previously encrypted values file.

You can use plain sops to decrypt specific files - https://github.com/mozilla/sops

Typical usage:
  $ helm secrets dec secrets/project/secrets.yaml

  # Decrypt file inline

  $ helm secrets dec -i secrets/project/secrets.yaml

EOF
}

decrypt_helper() {
    encrypted_file_path="${1}"
    type="${2:-"yaml"}"
    output="${3:-""}"

    if ! backend_is_file_encrypted "${encrypted_file_path}"; then
        return 1
    fi

    if [ "${output}" = "stdout" ]; then
        encrypted_file_dec=""
    elif [ "${output}" != "" ]; then
        encrypted_file_dec="${encrypted_file_path}"
    else
        encrypted_file_dec="$(_file_dec_name "${encrypted_file_path}")"
    fi

    if ! backend_decrypt_file "${type}" "${encrypted_file_path}" "${encrypted_file_dec}"; then
        rm -rf "${encrypted_file_dec}"
        fatal 'Error while decrypting file: %s' "${filename}"
    fi

    return 0
}

decrypt() {
    if is_help "$1"; then
        dec_usage
        return
    fi

    inline=false
    terraform=false

    argc=$#
    j=0

    while [ $j -lt $argc ]; do
        case "$1" in
        -i)
            inline=true
            ;;
        --terraform)
            terraform=true
            ;;
        *)
            set -- "$@" "$1"
            ;;
        esac

        shift
        j=$((j + 1))
    done

    filepath="$1"

    if [ "${terraform}" = "true" ] || [ "${inline}" = "false" ]; then
        output="stdout"
    else
        output="${filepath}"
    fi

    if ! encrypted_filepath=$(_file_get "${filepath}"); then
        fatal 'File does not exist: %s' "${filepath}"
    fi

    if ! content=$(decrypt_helper "${encrypted_filepath}" "auto" "${output}"); then
        fatal 'File is not encrypted: %s' "${encrypted_filepath}"
    fi

    if [ "${terraform}" = "true" ]; then
        printf '{"content_base64":"%s"}' "$(printf '%s' "${content}" | base64 | tr -d \\n)"
    else
        printf '%s' "${content}"
    fi
}
