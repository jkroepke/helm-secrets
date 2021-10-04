#!/usr/bin/env sh

set -eufx

# shellcheck source=scripts/commands/view.sh
. "${SCRIPT_DIR}/commands/view.sh"

downloader() {
    # https://helm.sh/docs/topics/plugins/#downloader-plugins
    # It's always the 4th parameter
    _file_url="${4}"
    file=$(printf '%s' "${4}" | sed -E -e 's!(sops|secrets?)(\+.+)?://!!')

    case "${_file_url}" in
    gpg-import+secrets://*)
        _gpg_key_and_file=$(printf '%s' "${4}" | sed -E -e 's!gpg-import\+secrets://!!')
        _gpg_key=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f1)
        file=$(printf '%s' "${_gpg_key_and_file}" | cut -d '?' -f2-)
        _gpg_init "${_gpg_key}"
    ;;
    *)
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

    gpg --batch --no-permission-warning --quiet --import "${_gpg_key}"
}
