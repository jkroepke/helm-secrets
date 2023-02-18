#!/usr/bin/env sh
if [ "${HELM_SECRETS_WRAPPER_ENABLED}" = "true" ]; then
    exec "${HELM_SECRETS_HELM_PATH:-${HELM_BIN:-"helm"}}" secrets "$@"
else
    exec "${HELM_SECRETS_HELM_PATH:-${HELM_BIN:-"helm"}}" "$@"
fi
