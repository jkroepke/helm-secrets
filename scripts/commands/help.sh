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
  enc     Encrypt secrets file
  dec     Decrypt secrets file
  view    Print secrets decrypted
  edit    Edit secrets file and encrypt afterwards
  clean   Remove all decrypted files in specified directory (recursively)
  dir     Get plugin directory
  <cmd>   wrapper that decrypts encrypted yaml files before running helm <cmd>

Available Options:
  --quiet       -q  Suppress info messages (env: $HELM_SECRETS_QUIET)
  --driver      -d  Secret driver to use for decryption or encryption (env: $HELM_SECRETS_DRIVER)
  --driver-args -a  Additional args for secret driver (env: $HELM_SECRETS_DRIVER_ARGS)
  --help        -h  Show help
EOF
}
