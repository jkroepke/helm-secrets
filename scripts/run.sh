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

if [ -n "${HELM_SECRETS_DRIVER+x}" ]; then
    if [ "${QUIET}" = "false" ]; then
        log 'The env var HELM_SECRETS_DRIVER is deprecated! Use HELM_SECRETS_BACKEND instead!'
    fi
    SECRET_BACKEND="${HELM_SECRETS_DRIVER}"
fi
if [ -n "${HELM_SECRETS_DRIVER_ARGS+x}" ]; then
    if [ "${QUIET}" = "false" ]; then
        log 'The env var HELM_SECRETS_DRIVER_ARGS is deprecated! Use HELM_SECRETS_BACKEND_ARGS instead!'
    fi
    SECRET_BACKEND_ARGS="${HELM_SECRETS_DRIVER_ARGS}"
fi

# The suffix to use for decrypted files. The default can be overridden using
# the HELM_SECRETS_DEC_SUFFIX environment variable.
# shellcheck disable=SC2034
DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX-}"
# shellcheck disable=SC2034
DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX-.dec}"

# shellcheck disable=SC2034
DEC_DIR="${HELM_SECRETS_DEC_DIR:-}"

trap _trap EXIT

load_secret_backend "$SECRET_BACKEND"

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
    terraform)
        # shellcheck source=scripts/commands/downloader.sh
        . "${SCRIPT_DIR}/commands/terraform.sh"

        terraform "$2"
        break
        ;;
    --help | -h | help)
        # shellcheck source=scripts/commands/help.sh
        . "${SCRIPT_DIR}/commands/help.sh"
        help_usage
        break
        ;;
    --version | -v | version)
        # shellcheck source=scripts/commands/version.sh
        . "${SCRIPT_DIR}/commands/version.sh"
        version
        break
        ;;
    --backend | -b)
        load_secret_backend "$2"
        shift
        ;;
    --driver | -d)
        if [ "${QUIET}" = "false" ]; then
            log 'The CLI arg '"$1"' is deprecated! --backend instead!'
        fi
        load_secret_backend "$2"
        shift
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
    --driver-args)
        if [ "${QUIET}" = "false" ]; then
            log 'The CLI arg '"$1"' is deprecated! --backend-args instead!'
        fi

        # shellcheck disable=SC2034
        SECRET_BACKEND_ARGS="$2"
        shift
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
