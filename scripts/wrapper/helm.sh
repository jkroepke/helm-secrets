#!/usr/bin/env sh

if [ "${HELM_SECRETS_WRAPPER_ENABLED}" = "true" ]; then
    if [ "$1" = "install" ] || [ "$1" = "upgrade" ] || [ "$1" = "template" ] || [ "$1" = "lint" ] || [ "$1" = "diff" ]; then
        exec "${HELM_SECRETS_HELM_PATH:-${HELM_BIN:-"helm"}}" secrets "$@"
    fi
fi

exec "${HELM_SECRETS_HELM_PATH:-${HELM_BIN:-"helm"}}" "$@"
