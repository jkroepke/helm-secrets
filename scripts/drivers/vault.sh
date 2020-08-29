#!/usr/bin/env sh

_VAULT_REGEX='!vault [A-z0-9][A-z0-9/\-]*\#[A-z0-9][A-z0-9-]*'

_sed_i() {
    # MacOS syntax is different for in-place
    if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

_regex_escape() {
    # This is a function because dealing with quotes is a pain.
    # http://stackoverflow.com/a/2705678/120999
    sed -e 's/[]\/()$*.^|[]/\\&/g'
}

driver_is_file_encrypted() {
    input="${1}"

    grep -q -e "${_VAULT_REGEX}" "${input}"
}

driver_encrypt_file() {
    echo "Encrypting files via vault driver is not supported!"
    exit 1
}

driver_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    if [ "${type}" != "yaml" ]; then
        echo "Only decryption of yaml files are allowed!"
        exit 1
    fi

    input_tmp="$(mktemp)"
    output_tmp="$(mktemp)"
    cp "${input}" "${input_tmp}"

    # Grab all patterns, deduplicate and pass it to loop
    # https://github.com/koalaman/shellcheck/wiki/SC2013
    grep -o -e "${_VAULT_REGEX}" "${input}" | sort | uniq | while IFS= read -r EXPRESSION; do
        # remove prefix
        VAULT_SECRET="${EXPRESSION#* }"
        VAULT_SECRET_PATH="${VAULT_SECRET%#*}"
        VAULT_SECRET_FIELD="${VAULT_SECRET#*#}"

        if ! SECRET="$(vault kv get -format=yaml -field="${VAULT_SECRET_FIELD}" "${VAULT_SECRET_PATH}")"; then
            echo "Error while get secret from vault!" >&2
            echo vault kv get -format=yaml -field="${VAULT_SECRET_FIELD}" "${VAULT_SECRET_PATH}" >&2
            exit 1
        fi

        # generate yaml anchor name
        YAML_ANCHOR=$(printf 'vault-%s-%s' "${VAULT_SECRET_PATH}" "${VAULT_SECRET_FIELD}" | tr '/' _)

        # Replace vault expression with yaml anchor
        EXPRESSION="$(echo "${EXPRESSION}" | _regex_escape)"
        _sed_i "s/${EXPRESSION}/*${YAML_ANCHOR}/g" "${input_tmp}"

        if [ "${VAULT_SECRET_FIELD}" = "data" ]; then
            {
                printf '.%s: &%s\n' "${YAML_ANCHOR}" "${YAML_ANCHOR}"
                printf '%s\n\n' "${SECRET}" | sed -e 's/^/  /g'
            } >>"${output_tmp}"
        else
            {
                printf '.%s: &%s ' "${YAML_ANCHOR}" "${YAML_ANCHOR}"
                printf '%s\n\n' "${SECRET}"
            } >>"${output_tmp}"
        fi
    done

    if [ "${output}" = "" ]; then
        cat "${output_tmp}" "${input_tmp}"
    else
        cat "${output_tmp}" "${input_tmp}" >"${output}"
    fi
}

driver_edit_file() {
    echo "Editing files via vault driver is not supported!"
    exit 1
}
