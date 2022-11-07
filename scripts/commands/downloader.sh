#!/usr/bin/env sh

set -euf

ALLOW_GPG_IMPORT="${HELM_SECRETS_ALLOW_GPG_IMPORT:-"true"}"
ALLOW_GPG_IMPORT_KUBERNETES="${HELM_SECRETS_ALLOW_GPG_IMPORT_KUBERNETES:-"true"}"
ALLOW_AGE_IMPORT="${HELM_SECRETS_ALLOW_AGE_IMPORT:-"true"}"
ALLOW_AGE_IMPORT_KUBERNETES="${HELM_SECRETS_ALLOW_AGE_IMPORT_KUBERNETES:-"true"}"

KEY_LOCATION_PREFIX="${HELM_SECRETS_KEY_LOCATION_PREFIX:-""}"

# shellcheck source=scripts/commands/decrypt.sh
. "${SCRIPT_DIR}/commands/decrypt.sh"

_trap_kill_gpg_agent() {
    if [ -n "${_GNUPGHOME+x}" ]; then
        if [ -f "${_GNUPGHOME}/.helm-secrets" ]; then
            # On CentOS 7, there is no kill option
            case $(gpgconf --help 2>&1) in
            *--kill*)
                gpgconf --kill gpg-agent
                ;;
            esac
        fi
    fi
}

downloader() {
    # https://helm.sh/docs/topics/plugins/#downloader-plugins
    # It's always the 4th parameter
    _file_url="${4}"

    case "${_file_url}" in
    secrets+gpg-import://*)
        if [ "${ALLOW_GPG_IMPORT}" != "true" ]; then
            fatal 'secrets+gpg-import:// is not allowed in this context!'
        fi

        _key_and_file=${4#*secrets+gpg-import://}

        # Ignore error on files beginning with ?
        if [ "${_key_and_file##\?}" != "${_key_and_file}" ]; then
            _key_and_file="${_key_and_file##\?}"
            IGNORE_MISSING_VALUES=true
        fi

        _key_path=$(printf '%s' "${_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_key_and_file}" | cut -d '?' -f2-)

        if ! _key_location_allowed "${_key_path}"; then
            fatal "Key location '%s' is not allowed" "${_key_path}"
        fi

        _gpg_init "${_key_path}"
        ;;
    secrets+gpg-import-kubernetes://*)
        if [ "${ALLOW_GPG_IMPORT_KUBERNETES}" != "true" ]; then
            fatal 'secrets+gpg-import-kubernetes:// is not allowed in this context!'
        fi

        _key_and_file=${4#*secrets+gpg-import-kubernetes://}

        # Ignore error on files beginning with ?
        if [ "${_key_and_file##\?}" != "${_key_and_file}" ]; then
            _key_and_file="${_key_and_file##\?}"
            IGNORE_MISSING_VALUES=true
        fi

        _key_location=$(printf '%s' "${_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_key_and_file}" | cut -d '?' -f2-)
        _gpg_init_kubernetes "${_key_location}"
        ;;
    secrets+age-import://*)
        if [ "${ALLOW_AGE_IMPORT}" != "true" ]; then
            fatal 'secrets+age-import:// is not allowed in this context!'
        fi

        _key_and_file=${_file_url#*secrets+age-import://}

        # Ignore error on files beginning with ?
        if [ "${_key_and_file##\?}" != "${_key_and_file}" ]; then
            _key_and_file="${_key_and_file##\?}"
            IGNORE_MISSING_VALUES=true
        fi

        _key_path=$(printf '%s' "${_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_key_and_file}" | cut -d '?' -f2-)

        if ! _key_location_allowed "${_key_path}"; then
            fatal "Key location '%s' is not allowed" "${_key_path}"
        fi

        _age_init "${_key_path}"
        ;;
    secrets+age-import-kubernetes://*)
        if [ "${ALLOW_AGE_IMPORT_KUBERNETES}" != "true" ]; then
            fatal 'secrets+age-import-kubernetes:// is not allowed in this context!'
        fi

        _key_and_file=${_file_url#*secrets+age-import-kubernetes://}

        # Ignore error on files beginning with ?
        if [ "${_key_and_file##\?}" != "${_key_and_file}" ]; then
            _key_and_file="${_key_and_file##\?}"
            IGNORE_MISSING_VALUES=true
        fi

        _key_location=$(printf '%s' "${_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_key_and_file}" | cut -d '?' -f2-)
        _age_init_kubernetes "${_key_location}"
        ;;
    secrets+literal://*)
        literal="${_file_url#*secrets+literal://}"

        if ! backend_decrypt_literal "${literal}"; then
            exit 1
        fi

        return
        ;;
    secrets://*)
        file="${_file_url#*secrets://}"
        ;;
    *)
        fatal "Unknown protocol '%s'!" "${_file_url}"
        ;;
    esac

    if ! encrypted_filepath=$(_file_get "${file}"); then
        if [ "${IGNORE_MISSING_VALUES}" = "true" ]; then
            printf ''
            return
        else
            fatal 'File does not exist: %s' "${file}"
        fi
    fi

    if ! decrypt_helper "${encrypted_filepath}" "auto" "stdout"; then
        cat "${encrypted_filepath}"
    fi
}

_gpg_init() {
    _GNUPGHOME=$(_mktemp -d)
    touch "${_GNUPGHOME}/.helm-secrets"

    GNUPGHOME="${_GNUPGHOME}"
    export GNUPGHOME

    gpg --batch --no-permission-warning --quiet --import "${1}"
}

_gpg_init_kubernetes() {
    _secret_location="${1%#*}"
    _secret_key="${1#*#}"

    case "${1}" in
    */*)
        _kubernetes_namespace="${_secret_location%/*}"
        _kubernetes_secret_name="${_secret_location#*/}"
        ;;
    *)
        _kubernetes_secret_name="${_secret_location}"
        ;;
    esac

    _key_path="$(_mktemp)"

    if ! "${HELM_SECRETS_KUBECTL_PATH:-kubectl}" get secret ${_kubernetes_namespace+-n ${_kubernetes_namespace}} "${_kubernetes_secret_name}" \
        -o "go-template={{ index .data \"${_secret_key}\" }}" >"${_key_path}.base64"; then
        fatal "Couldn't get kubernetes secret %s%s" "${_kubernetes_namespace+${_kubernetes_namespace}/}" "${_kubernetes_secret_name}"
    fi

    if ! base64 --decode <"${_key_path}.base64" >"${_key_path}"; then
        fatal "Couldn't find key %s in secret %s" "${_secret_key}" "${_kubernetes_secret_name}"
    fi

    _gpg_init "${_key_path}"
}

_age_init() {
    export SOPS_AGE_KEY_FILE="${1}"
}

_age_init_kubernetes() {
    _secret_location="${1%#*}"
    _secret_key="${1#*#}"

    case "${1}" in
    */*)
        _kubernetes_namespace="${_secret_location%/*}"
        _kubernetes_secret_name="${_secret_location#*/}"
        ;;
    *)
        _kubernetes_secret_name="${_secret_location}"
        ;;
    esac

    _key_path="$(_mktemp)"

    if ! "${HELM_SECRETS_KUBECTL_PATH:-kubectl}" get secret ${_kubernetes_namespace+-n ${_kubernetes_namespace}} "${_kubernetes_secret_name}" \
        -o "go-template={{ index .data \"${_secret_key}\" }}" >"${_key_path}.base64"; then
        fatal "Couldn't get kubernetes secret %s" "${_kubernetes_namespace+${_kubernetes_namespace}/}${_kubernetes_secret_name}"
    fi

    if ! base64 --decode <"${_key_path}.base64" >"${_key_path}"; then
        fatal "Couldn't find key %s in kubernetes secret %s" "${_secret_key}" "${_kubernetes_secret_name}"
    fi

    _age_init "${_key_path}"
}

_key_location_allowed() {
    case "${1}" in
    "${KEY_LOCATION_PREFIX}"*)
        true
        ;;
    *)
        false
        ;;
    esac
}
