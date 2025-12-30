#!/usr/bin/env sh

set -euf

dec_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] decrypt [ -i ] [ --terraform ] <path to file>

Decrypt secrets

It uses your gpg credentials to decrypt previously encrypted values file.

You can use plain sops to decrypt specific files - https://github.com/getsops/sops

Typical usage:
  $ helm secrets decrypt secrets/project/secrets.yaml

  # Decrypt file inline

  $ helm secrets decrypt -i secrets/project/secrets.yaml

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
        encrypted_file_dec="${output}"
    else
        encrypted_file_dec="$(_file_dec_name "${encrypted_file_path}")"
    fi

    if ! backend_decrypt_file "${type}" "${encrypted_file_path}" "${encrypted_file_dec}"; then
        if [ "${output}" = "" ] && [ "${output}" != "stdout" ]; then
            rm -rf "$(_file_dec_name "${encrypted_file_path}")"
        fi

        fatal 'Error while decrypting file: %s' "${encrypted_file_path}"
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

    # Skip decryption if SKIP_DECRYPT is set
    if [ "${SKIP_DECRYPT}" = "true" ]; then
        if [ "${QUIET}" = "false" ]; then
            log 'Decrypt skipped (--skip-decrypt): %s' "${filepath}" >&2
        fi
        # Output the encrypted file as-is
        content=$(cat "${encrypted_filepath}" && printf '_')
        content="${content%_}"

        if [ "${terraform}" = "true" ]; then
            printf '{"content_base64":"%s"}' "$(printf '%s' "${content}" | base64 | tr -d \\n)"
        else
            printf '%s' "${content}"
        fi
        return 0
    fi

    # Append an underscore to the end of the content to prevent the stripping of trailing newlines
    # occurring during command substitution.
    if ! content=$(decrypt_helper "${encrypted_filepath}" "auto" "${output}" && printf '_'); then
        fatal 'File is not encrypted: %s' "${encrypted_filepath}"
    fi

    # Remove the underscore again.
    content="${content%_}"

    if [ "${terraform}" = "true" ]; then
        printf '{"content_base64":"%s"}' "$(printf '%s' "${content}" | base64 | tr -d \\n)"
    else
        printf '%s' "${content}"
    fi
}
