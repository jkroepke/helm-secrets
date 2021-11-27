#!/usr/bin/env sh

set -euf

ALLOW_GPG_IMPORT="${HELM_SECRETS_ALLOW_GPG_IMPORT:-"true"}"
ALLOW_GPG_IMPORT_KUBERNETES="${HELM_SECRETS_ALLOW_GPG_IMPORT_KUBERNETES:-"true"}"
ALLOW_AGE_IMPORT="${HELM_SECRETS_ALLOW_AGE_IMPORT:-"true"}"
ALLOW_AGE_IMPORT_KUBERNETES="${HELM_SECRETS_ALLOW_AGE_IMPORT_KUBERNETES:-"true"}"

# shellcheck source=scripts/commands/view.sh
. "${SCRIPT_DIR}/commands/view.sh"

_trap_hook() {
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
            error "[helm-secret] secrets+gpg-import:// is not allowed in this context!"
        fi

        _gpg_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!secrets\+gpg-import://!!')
        _gpg_key_path=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f2-)
        _gpg_init "${_gpg_key_path}"
        ;;
    secrets+gpg-import-kubernetes://*)
        if [ "${ALLOW_GPG_IMPORT_KUBERNETES}" != "true" ]; then
            error "[helm-secret] secrets+gpg-import-kubernetes:// is not allowed in this context!"
        fi

        _gpg_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!secrets\+gpg-import-kubernetes://!!')
        _gpg_key_location=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f2-)
        _gpg_init_kubernetes "${_gpg_key_location}"
        ;;
    secrets+age-import://*)
        if [ "${ALLOW_AGE_IMPORT}" != "true" ]; then
            error "[helm-secret] secrets+age-import:// is not allowed in this context!"
        fi

        _age_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!secrets\+age-import://!!')
        _age_key_path=$(printf '%s' "${_age_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_age_key_and_file}" | cut -d '?' -f2-)
        _age_init "${_age_key_path}"
        ;;
    secrets+age-import-kubernetes://*)
        if [ "${ALLOW_AGE_IMPORT_KUBERNETES}" != "true" ]; then
            error "[helm-secret] secrets+age-import-kubernetes:// is not allowed in this context!"
        fi

        _age_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!secrets\+age-import-kubernetes://!!')
        _age_key_location=$(printf '%s' "${_age_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_age_key_and_file}" | cut -d '?' -f2-)
        _age_init_kubernetes "${_age_key_location}"
        ;;
    sops://*)
        echo '[helm-secrets] sops:// is deprecated. Use secrets://' >&2
        file=$(printf '%s' "${_file_url}" | sed -E -e 's!sops://!!')
        ;;
    secret://*)
        echo '[helm-secrets] secret:// is deprecated. Use secrets://' >&2
        file=$(printf '%s' "${_file_url}" | sed -E -e 's!secret://!!')
        ;;
    secrets://*)
        file=$(printf '%s' "${_file_url}" | sed -E -e 's!secrets://!!')
        ;;
    *)
        error "[helm-secrets] Unknown protocol '${_file_url}'!"
        ;;
    esac

    view_helper "${file}"
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

    _gpg_key_path="$(_mktemp)"

    if ! "${HELM_SECRETS_KUBECTL_PATH:-kubectl}" get secret ${_kubernetes_namespace+-n ${_kubernetes_namespace}} "${_kubernetes_secret_name}" \
        -o "go-template={{ index .data \"${_secret_key}\" }}" >"${_gpg_key_path}.base64"; then
        error "[helm-secrets] Couldn't get kubernetes secret ${_kubernetes_namespace+${_kubernetes_namespace}/}${_kubernetes_secret_name}"
    fi

    if ! base64 --decode <"${_gpg_key_path}.base64" >"${_gpg_key_path}"; then
        error "[helm-secrets] Couldn't find key ${_secret_key} in secret ${_kubernetes_secret_name}"
    fi

    _gpg_init "${_gpg_key_path}"
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

    _age_key_path="$(_mktemp)"

    if ! "${HELM_SECRETS_KUBECTL_PATH:-kubectl}" get secret ${_kubernetes_namespace+-n ${_kubernetes_namespace}} "${_kubernetes_secret_name}" \
        -o "go-template={{ index .data \"${_secret_key}\" }}" >"${_age_key_path}.base64"; then
        error "[helm-secrets] Couldn't get kubernetes secret ${_kubernetes_namespace+${_kubernetes_namespace}/}${_kubernetes_secret_name}"
    fi

    if ! base64 --decode <"${_age_key_path}.base64" >"${_age_key_path}"; then
        error "[helm-secrets] Couldn't find key ${_secret_key} in secret ${_kubernetes_secret_name}"
    fi

    _age_init "${_age_key_path}"
}
