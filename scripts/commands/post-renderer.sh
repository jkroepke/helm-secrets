#!/usr/bin/env sh

set -euf

post_renderer() {
    if [ "${EVALUATE_TEMPLATES_DECODE_SECRETS}" = "true" ]; then
        SECRET_BACKEND_ARGS="${SECRET_BACKEND_ARGS:-} -decode-kubernetes-secrets"
    fi

    _vals_backend_decrypt_file "yaml" "-"
}
