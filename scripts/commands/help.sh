#!/usr/bin/env sh

set -euf

help_usage() {
    cat <<'EOF'
Secrets encryption in Helm Charts

This plugin provides ability to encrypt/decrypt secrets files
to store in less secure places, before they are installed using
Helm.

For more information, see the README at github.com/jkroepke/helm-secrets

To decrypt/encrypt/edit you need to initialize/first encrypt secrets with
sops - https://github.com/mozilla/sops

Available Commands:
  encrypt Encrypt secrets file
  decrypt Decrypt secrets file
  edit    Edit secrets file and encrypt afterwards
  dir     Get plugin directory
  patch   Enables windows specific adjustments
  <cmd>   wrapper that decrypts encrypted yaml files before running helm <cmd>

Available Options:
  --quiet                               -q  Suppress info messages (env: $HELM_SECRETS_QUIET)
  --backend                             -b  Secret backend to use for decryption or encryption (env: $HELM_SECRETS_BACKEND)
  --backend-args                        -a  Additional args for secret backend (env: $HELM_SECRETS_BACKEND_ARGS)
  --ignore-missing-values [true|false]      Ignore missing value files (env: $HELM_SECRETS_IGNORE_MISSING_VALUES)
  --help                                -h  Show help
  --version                             -v  Display version of helm-secrets
EOF
}
