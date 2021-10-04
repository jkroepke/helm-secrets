#!/usr/bin/env sh

set -euf

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
        _gpg_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!secrets\+gpg-import://!!')
        _gpg_key_path=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f2-)
        _gpg_init "${_gpg_key_path}"
        ;;
    secrets+gpg-import-kubernetes://*)
        _gpg_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!secrets\+gpg-import-kubernetes://!!')
        _gpg_key_location=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f2-)
        _gpg_init_kubernetes "${_gpg_key_location}"
        ;;
    *)
        case "${_file_url}" in
        sops://*)
            printf '[helm-secrets] sops:// is deprecated. Use secrets://'
            ;;
        secret://*)
            printf '[helm-secrets] secret:// is deprecated. Use secrets://'
            ;;
        esac

        file=$(printf '%s' "${4}" | sed -E -e 's!(sops|secrets?)://!!')
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

    "${HELM_SECRETS_KUBECTL_PATH:-kubectl}" get secret ${_kubernetes_namespace+-n ${_kubernetes_namespace}} "${_kubernetes_secret_name}" \
        -o "go-template={{ index .data \"${_secret_key}\" }}" >"${_gpg_key_path}.base64"

    if base64 -d <"${_gpg_key_path}.base64" >"${_gpg_key_path}"; then
        error "Couldn't find key ${_secret_key} in secret ${_kubernetes_secret_name}"
    fi

    _gpg_init "${_gpg_key_path}"
}
