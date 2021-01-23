#!/usr/bin/env sh

# shellcheck source=scripts/lib/http.sh
. "${SCRIPT_DIR}/lib/sed.sh"

_custom_driver_is_yaml() {
    false
}

_custom_driver_get_secret() {
    echo "Please override function '_custom_driver_get_secret' in your driver!" >&2
    exit 1
}

driver_is_file_encrypted() {
    input="${1}"

    grep -q -e "${_DRIVER_REGEX}" "${input}"
}

driver_encrypt_file() {
    echo "Encrypting files is not supported!"
    exit 1
}

driver_decrypt_file() {
    type="${1}"
    input="${2}"
    # if omit then output to stdout
    output="${3:-}"

    output_yaml="$(mktemp)"
    output_yaml_anchors="$(mktemp)"

    # Strip yaml separator
    sed -e '/^---$/d' "${input}" >"${output_yaml}"

    # Grab all patterns, deduplicate and pass it to loop
    # https://github.com/koalaman/shellcheck/wiki/SC2013
    if ! grep -o -e "${_DRIVER_REGEX}" "${input}" | sort | uniq | while IFS= read -r EXPRESSION; do
        # remove prefix
        _SECRET="${EXPRESSION#* }"

        if ! SECRET=$(_custom_driver_get_secret "${type}" "${_SECRET}"); then
            exit 1
        fi

        # generate yaml anchor name
        YAML_ANCHOR=$(printf 'helm-secret-%s' "${_SECRET}" | tr '#$/' '_')

        # Replace vault expression with yaml anchor
        EXPRESSION="$(echo "${EXPRESSION}" | _regex_escape)"
        _sed_i "s/${EXPRESSION}/*${YAML_ANCHOR}/g" "${output_yaml}"

        if _custom_driver_is_yaml "${type}" "${_SECRET}"; then
            {
                printf '.%s: &%s\n' "${YAML_ANCHOR}" "${YAML_ANCHOR}"
                printf '%s\n\n' "${SECRET}" | sed -e 's/^/  /g'
            } >>"${output_yaml_anchors}"
        else
            {
                printf '.%s: &%s ' "${YAML_ANCHOR}" "${YAML_ANCHOR}"
                printf '%s\n\n' "${SECRET}"
            } >>"${output_yaml_anchors}"
        fi
    done; then
        # pass exit from pipe/sub shell to main shell
        exit 1
    fi

    if [ "${output}" = "" ]; then
        cat "${output_yaml_anchors}" "${output_yaml}"
    else
        cat "${output_yaml_anchors}" "${output_yaml}" >"${output}"
    fi
}

driver_edit_file() {
    echo "Editing files is not supported!"
    exit 1
}
