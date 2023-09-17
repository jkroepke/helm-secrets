#!/usr/bin/env sh

set -euf

help_usage() {
    cat <<'EOF'

helm-secrets is a helm plugin for decrypt encrypted helm value files on the fly.

For more information, see the README.md at https://github.com/jkroepke/helm-secrets

To decrypt/encrypt/edit locally you need to initialize/first encrypt secrets with
sops - https://github.com/getsops/sops

Available Commands:
  encrypt Encrypt secrets file
  decrypt Decrypt secrets file
  edit    Edit secrets file and encrypt afterwards
  dir     Get plugin directory
  patch   Enables windows specific adjustments
  <cmd>   wrapper that decrypts encrypted yaml files before running helm <cmd>

Available Options:
  --quiet                                          -q  Suppress info messages (env: $HELM_SECRETS_QUIET)
  --backend                                        -b  Secret backend to use for decryption or encryption (env: $HELM_SECRETS_BACKEND)
  --backend-args                                   -a  Additional args for secret backend (env: $HELM_SECRETS_BACKEND_ARGS)
  --ignore-missing-values [true|false]                 Ignore missing value files (env: $HELM_SECRETS_IGNORE_MISSING_VALUES)
  --evaluate-templates [true|false]                    Evaluate secret expressions inside helm template (only supported by vals backend) (env: $HELM_SECRETS_EVALUATE_TEMPLATES)
  --evaluate-templates-decode-secrets [true|false]     If --evaluate-templates is set, decode base64 values from secrets to evaluate them (env: $HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS)
  --decrypt-secrets-in-tmp-dir [true|false]            Decrypt secrets in a temp directory. May solve concurrency issues. (env: $HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR)
  --help                                           -h  Show help
  --version                                        -v  Display version of helm-secrets
EOF
}
