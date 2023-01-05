#!/usr/bin/env sh

set -euf

post_renderer() {
    if [ "${EVALUATE_TEMPLATES_DECODE_SECRETS}" = "true" ]; then
        _vals ksdecode -f - | backend_decrypt_file "yaml" "-"
    else
        cat -
    fi
}
