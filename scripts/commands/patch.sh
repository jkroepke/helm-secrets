#!/usr/bin/env sh

set -euf

patch_usage() {
    cat <<EOF
helm secrets patch [unix|windows]

This enables windows specific options to increase the helm-secrets compatibility with windows.

If unix is selected, it reverts the windows specific options.

EOF
}

patch() {
    if is_help "$1"; then
        install_usage
        return
    fi

    case "$1" in
    windows)
        _sed_i 's!  - command: .*!  - command: "scripts/wrapper/run.cmd scripts/run.sh downloader"!' "${HELM_PLUGIN_DIR}/plugin.yaml"
        ;;
    unix)
        _sed_i 's!  - command: .*!  - command: "scripts/run.sh downloader"!' "${HELM_PLUGIN_DIR}/plugin.yaml"
        ;;
    *)
        fatal 'Unknown enable option %s' "$1"
        ;;
    esac
}
