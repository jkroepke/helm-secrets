#!/usr/bin/env sh

set -euf

if [ "${HELM_DEBUG:-}" = "1" ] || [ "${HELM_DEBUG:-}" = "true" ] || [ -n "${HELM_SECRETS_DEBUG+x}" ]; then
    set -x
fi

# Path to current directory
SCRIPT_DIR="${HELM_PLUGIN_DIR}/scripts"

# shellcheck source=scripts/lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

# shellcheck source=scripts/lib/expand_vars_strict.sh
. "${SCRIPT_DIR}/lib/expand_vars_strict.sh"

# shellcheck source=scripts/lib/file.sh
. "${SCRIPT_DIR}/lib/file.sh"

# shellcheck source=scripts/lib/backend.sh
. "${SCRIPT_DIR}/lib/backend.sh"

# shellcheck source=scripts/lib/http.sh
. "${SCRIPT_DIR}/lib/http.sh"

# Make sure HELM_BIN is set (normally by the helm command)
HELM_BIN="${HELM_SECRETS_HELM_PATH:-"${HELM_BIN:-helm}"}"

if on_cygwin; then
    HELM_BIN="$(cygpath -u "${HELM_BIN}")"
fi

# Create a base temporary directory
TMPDIR="${HELM_SECRETS_DEC_TMP_DIR:-"$(mktemp -d)"}"
export TMPDIR
mkdir -p "${TMPDIR}"

# Output debug infos
if [ -n "${ARGOCD_APP_NAME+x}" ]; then
    QUIET="${HELM_SECRETS_QUIET:-true}"
else
    QUIET="${HELM_SECRETS_QUIET:-false}"
fi

# Define the secret backend
SECRET_BACKEND="${HELM_SECRETS_BACKEND:-sops}"
# Define the secret backend custom args
SECRET_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS:-}"

# The suffix to use for decrypted files. The default can be overridden using
# the HELM_SECRETS_DEC_SUFFIX environment variable.
# shellcheck disable=SC2034
DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX-}"
# shellcheck disable=SC2034
DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX-.dec}"

# shellcheck disable=SC2034
DEC_DIR="${HELM_SECRETS_DEC_DIR:-}"
# shellcheck disable=SC2034
IGNORE_MISSING_VALUES="${HELM_SECRETS_IGNORE_MISSING_VALUES:-false}"
# shellcheck disable=SC2034
EVALUATE_TEMPLATES="${HELM_SECRETS_EVALUATE_TEMPLATES:-false}"
# shellcheck disable=SC2034
EVALUATE_TEMPLATES_DECODE_SECRETS="${HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS:-false}"
# shellcheck disable=SC2034
DECRYPT_SECRETS_IN_TMP_DIR="${HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR:-false}"
# shellcheck disable=SC2034
LOAD_GPG_KEYS="${HELM_SECRETS_LOAD_GPG_KEYS:-false}"

trap _trap EXIT
trap 'trap - EXIT; _trap; exit 1' HUP INT QUIT TERM

load_secret_backend "${SECRET_BACKEND}"
DEFAULT_SECRET_BACKEND="${SECRET_BACKEND}"

if [ "${LOAD_GPG_KEYS}" != "false" ]; then
    _gpg_load_keys
fi

if [ -n "${HELM_SECRET_WSL_INTEROP+x}" ]; then
    shift
    argc=$#
    j=0

    while [ $j -lt $argc ]; do
        case "$1" in
        *\\*)
            set -- "$@" "$(wslpath "$(printf '%s' "$1" | tr "\\" '/')")"
            ;;
        *)
            set -- "$@" "$1"
            ;;
        esac

        shift
        j=$((j + 1))
    done
fi

while true; do
    case "${1:-}" in
    encrypt)
        # shellcheck source=scripts/commands/encrypt.sh
        . "${SCRIPT_DIR}/commands/encrypt.sh"

        if [ $# -lt 2 ]; then
            enc_usage
            echo "Error: secrets file required."
            exit 1
        fi

        shift
        encrypt "$@"
        break
        ;;
    decrypt)
        # shellcheck source=scripts/commands/decrypt.sh
        . "${SCRIPT_DIR}/commands/decrypt.sh"

        if [ $# -lt 2 ]; then
            dec_usage
            echo "Error: secrets file required."
            exit 1
        fi

        shift
        decrypt "$@"
        break
        ;;
    edit)
        # shellcheck source=scripts/commands/edit.sh
        . "${SCRIPT_DIR}/commands/edit.sh"

        if [ $# -lt 2 ]; then
            edit_usage
            echo "Error: secrets file required."
            exit 1
        fi
        edit "$2"
        break
        ;;
    dir)
        _helm_winpath "$(dirname "${SCRIPT_DIR}")"
        break
        ;;
    post-renderer)
        # shellcheck source=scripts/commands/downloader.sh
        . "${SCRIPT_DIR}/commands/post-renderer.sh"

        post_renderer
        break
        ;;
    downloader)
        # shellcheck source=scripts/commands/downloader.sh
        . "${SCRIPT_DIR}/commands/downloader.sh"

        downloader "$2" "$3" "$4" "$5"
        break
        ;;
    patch)
        # shellcheck source=scripts/commands/patch.sh
        . "${SCRIPT_DIR}/commands/patch.sh"

        patch "$2"
        break
        ;;
    --help | -h | help)
        # shellcheck source=scripts/commands/help.sh
        . "${SCRIPT_DIR}/commands/help.sh"
        help_usage
        break
        ;;
    --version | -v)
        # shellcheck source=scripts/commands/version.sh
        . "${SCRIPT_DIR}/commands/version.sh"
        version
        break
        ;;
    --backend | -b)
        load_secret_backend "${2}"
        DEFAULT_SECRET_BACKEND="${SECRET_BACKEND}"
        shift
        ;;
    --backend=*)
        load_secret_backend "${1#*=}"
        DEFAULT_SECRET_BACKEND="${SECRET_BACKEND}"
        ;;
    --quiet | -q)
        # shellcheck disable=SC2034
        QUIET=true
        ;;
    --backend-args | -a)
        # shellcheck disable=SC2034
        SECRET_BACKEND_ARGS="$2"
        shift
        ;;
    --backend-args=*)
        # shellcheck disable=SC2034
        SECRET_BACKEND_ARGS="${1#*=}"
        ;;
    --ignore-missing-values)
        if [ "$2" = "true" ] || [ "$2" = "false" ]; then
            # shellcheck disable=SC2034
            IGNORE_MISSING_VALUES="$2"
            shift
        else
            # shellcheck disable=SC2034
            IGNORE_MISSING_VALUES="true"
        fi
        ;;
    --ignore-missing-values=*)
        # shellcheck disable=SC2034
        IGNORE_MISSING_VALUES="${1#*=}"
        ;;
    --evaluate-templates)
        if [ "$2" = "true" ] || [ "$2" = "false" ]; then
            # shellcheck disable=SC2034
            EVALUATE_TEMPLATES="$2"
            shift
        else
            # shellcheck disable=SC2034
            EVALUATE_TEMPLATES="true"
        fi
        ;;
    --evaluate-templates=*)
        # shellcheck disable=SC2034
        EVALUATE_TEMPLATES="${1#*=}"
        ;;
    --evaluate-templates-decode-secrets)
        if [ "$2" = "true" ] || [ "$2" = "false" ]; then
            # shellcheck disable=SC2034
            EVALUATE_TEMPLATES_DECODE_SECRETS="$2"
            shift
        else
            # shellcheck disable=SC2034
            EVALUATE_TEMPLATES_DECODE_SECRETS="true"
        fi
        ;;
    --evaluate-templates-decode-secrets=*)
        # shellcheck disable=SC2034
        EVALUATE_TEMPLATES_DECODE_SECRETS="${1#*=}"
        ;;
    --decrypt-secrets-in-tmp-dir)
        if [ "$2" = "true" ] || [ "$2" = "false" ]; then
            # shellcheck disable=SC2034
            DECRYPT_SECRETS_IN_TMP_DIR="$2"
            shift
        else
            # shellcheck disable=SC2034
            DECRYPT_SECRETS_IN_TMP_DIR="true"
        fi
        ;;
    --decrypt-secrets-in-tmp-dir=*)
        # shellcheck disable=SC2034
        DECRYPT_SECRETS_IN_TMP_DIR="${1#*=}"
        ;;
    "")
        # shellcheck source=scripts/commands/help.sh
        . "${SCRIPT_DIR}/commands/help.sh"
        help_usage
        exit 1
        ;;
    *)
        # shellcheck source=scripts/commands/helm.sh
        . "${SCRIPT_DIR}/commands/helm.sh"
        helm_command "$@"
        break
        ;;
    esac

    shift
done

exit 0
