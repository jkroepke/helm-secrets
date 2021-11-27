#!/usr/bin/env sh

set -euf

# shellcheck source=scripts/commands/view.sh
. "${SCRIPT_DIR}/commands/view.sh"

terraform_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] terraform <path to file>

Subcommand which is compatible with terraform external data source provider.
https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source

Typical usage:
  $ helm secrets terraform secrets/myproject/nginx/secrets.yaml

Example output: {"content_base64":"<base64 coded content of value file>"}

EOF
}

terraform() {
    if is_help "$1"; then
        terraform_usage
        exit 1
    fi

    if ! content=$(view_helper "$1"); then
        exit 1
    fi

    printf '{"content_base64":"%s"}' "$(printf '%s' "${content}" | base64)"
}
