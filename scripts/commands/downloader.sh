#!/usr/bin/env sh

set -eu

# shellcheck source=scripts/commands/view.sh
. "${SCRIPT_DIR}/commands/view.sh"

downloader() {
    # https://helm.sh/docs/topics/plugins/#downloader-plugins
    # It's always the 4th parameter
    file=$(printf '%s' "${4}" | sed -E -e 's!(sops|secrets?)://!!')

    view_helper "${file}"
}
