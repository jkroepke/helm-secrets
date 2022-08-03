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

OUTPUT_DECRYPTED_FILE_PATH="${HELM_SECRETS_OUTPUT_DECRYPTED_FILE_PATH:-false}"

# Output debug infos
if [ -n "${ARGOCD_APP_NAME+x}" ]; then
    QUIET="${HELM_SECRETS_QUIET:-true}"
else
    QUIET="${HELM_SECRETS_QUIET:-"${OUTPUT_DECRYPTED_FILE_PATH}"}"
fi

# Define the secret driver engine
SECRET_DRIVER="${HELM_SECRETS_DRIVER:-sops}"
# Define the secret driver engine args
SECRET_DRIVER_ARGS="${HELM_SECRETS_DRIVER_ARGS:-}"

# The suffix to use for decrypted files. The default can be overridden using
# the HELM_SECRETS_DEC_SUFFIX environment variable.
# shellcheck disable=SC2034
DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX-}"
# shellcheck disable=SC2034
DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX-.dec}"

# shellcheck disable=SC2034
DEC_DIR="${HELM_SECRETS_DEC_DIR:-}"

trap _trap EXIT

load_secret_driver "$SECRET_DRIVER"

if [ -n "${HELM_SECRET_WSL_INTEROP+x}" ]; then
    shift
    argc=$#
    j=0

    SKIP_ARG_PARSE=false
    while [ $j -lt $argc ]; do
        if [ "${SKIP_ARG_PARSE}" = "true" ]; then
            set -- "$@" "$1"
        else
            case "$1" in
            *\\*)
                set -- "$@" "$(wslpath "$(printf '%s' "$1" | tr "\\" '/')")"
                ;;
            --)
                # skip --, and what remains are the cmd args
                SKIP_ARG_PARSE=true
                set -- "$@" "$1"
                ;;
            *)
                set -- "$@" "$1"
                ;;
            esac
        fi

        shift
        j=$((j + 1))
    done
fi

while true; do
    case "${1:-}" in
    enc)
        # shellcheck source=scripts/commands/enc.sh
        . "${SCRIPT_DIR}/commands/enc.sh"

        if [ $# -lt 2 ]; then
            enc_usage
            echo "Error: secrets file required."
            exit 1
        fi
        enc "$2"
        break
        ;;
    dec)
        # shellcheck source=scripts/commands/dec.sh
        . "${SCRIPT_DIR}/commands/dec.sh"

        if [ $# -lt 2 ]; then
            dec_usage
            echo "Error: secrets file required."
            exit 1
        fi
        dec "$2"
        break
        ;;
    view)
        # shellcheck source=scripts/commands/view.sh
        . "${SCRIPT_DIR}/commands/view.sh"

        if [ $# -lt 2 ]; then
            view_usage
            echo "Error: secrets file required."
            exit 1
        fi
        view "$2"
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
    clean)
        # shellcheck source=scripts/commands/clean.sh
        . "${SCRIPT_DIR}/commands/clean.sh"

        if [ $# -lt 2 ]; then
            clean_usage
            echo "Error: Chart package required."
            exit 1
        fi
        clean "$2"
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
    --driver | -d)
        load_secret_driver "$2"
        shift
        ;;
    --output-decrypt-file-path)
        # shellcheck disable=SC2034
        OUTPUT_DECRYPTED_FILE_PATH=true
        QUIET=true
        ;;
    --quiet | -q)
        # shellcheck disable=SC2034
        QUIET=true
        ;;
    --driver-args | -a)
        # shellcheck disable=SC2034
        SECRET_DRIVER_ARGS="$2"
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
