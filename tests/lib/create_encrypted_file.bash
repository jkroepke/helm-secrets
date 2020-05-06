create_encrypted_file() {
    {
        file="${2:-secrets.yaml}"
        case "${3:-${HELM_SECRETS_DRIVER}}" in
        noop)
            (
                # shellcheck disable=SC2164
                cd "${TEST_TEMP_DIR}"
                echo "$1" >"${file}"
            )
            ;;
        sops)
            (
                # shellcheck disable=SC2164
                cd "${TEST_TEMP_DIR}"
                # shellcheck disable=SC2059
                printf "$1" >"${file}"
                sops -e -i "${file}"
            )
            ;;
        vault)
            (
                # shellcheck disable=SC2164
                cd "${TEST_TEMP_DIR}"

                # Check for multiline
                if echo "$1" | grep -q ': |'; then
                    # shellcheck disable=SC2059
                    secret_content="$(printf "$1" | tail -n +2 | sed -e 's/^  //g')"
                    secret_key="$(printf '%s' "$secret_content" | _shasum | cut -d' ' -f1)"
                else
                    # shellcheck disable=SC2059
                    secret_content="$(printf "$1" | cut -d: -f2 | tr -d ' ')"
                    secret_key="$(printf '%s' "$secret_content" | _shasum | cut -d' ' -f1)"
                fi

                printf '%s: !vault secret/%s#key' "$(echo "$1" | cut -d: -f1)" "${secret_key}" >"${file}"
                printf '%s' "${secret_content}" | vault kv put "secret/${secret_key}" key=-
            )
            ;;
        *)
            echo "Unknown driver ${HELM_SECRETS_DRIVER}"
            ;;

        esac
    } >&2
}
