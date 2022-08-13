#!/usr/bin/env bash

create_encrypted_file() {
    {
        file="${2:-secrets.yaml}"
        case "${3:-${HELM_SECRETS_BACKEND}}" in
        sops)
            # shellcheck disable=SC2059
            printf "$1" >"${TEST_TEMP_DIR}/${file}"
            (cd "${TEST_TEMP_DIR}" && exec "${SOPS_BIN}" -e -i "${file}")
            ;;
        vals)
            # shellcheck disable=SC2059
            printf "$1" >"${TEST_TEMP_DIR}/vals.${file}"
            yaml_key="$(echo "$1" | cut -d: -f1)"
            printf '%s: ref+file://%s#%s' "${yaml_key}" "${TEST_TEMP_DIR}/vals.${file}" "${yaml_key}" >"${TEST_TEMP_DIR}/${file}"
            ;;
        noop)
            # shellcheck disable=SC2059
            printf "$1" >"${TEST_TEMP_DIR}/${file}"
            ;;
        *)
            echo "Unknown backend ${HELM_SECRETS_BACKEND}"
            exit 1
            ;;
        esac
    } >&2
}
