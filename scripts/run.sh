#!/usr/bin/env sh

set -euf

# Path to current directory
SCRIPT_DIR="$(dirname "$0")"

# Create temporary directory
TMPDIR="${HELM_SECRETS_DEC_TMP_DIR:-$(mktemp -d)}"

# Output debug infos
QUIET="${HELM_SECRETS_QUIET:-false}"

# Define the secret driver engine
SECRET_DRIVER="${HELM_SECRETS_DRIVER:-sops}"

# The suffix to use for decrypted files. The default can be overridden using
# the HELM_SECRETS_DEC_SUFFIX environment variable.
DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX:-.yaml.dec}"
DEC_DIR="${HELM_SECRETS_DEC_DIR:-}"

# Make sure HELM_BIN is set (normally by the helm command)
HELM_BIN="${HELM_BIN:-helm}"

# shellcheck source=scripts/lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

# shellcheck source=scripts/lib/file.sh
. "${SCRIPT_DIR}/lib/file.sh"

# shellcheck source=scripts/lib/http.sh
. "${SCRIPT_DIR}/lib/http.sh"

trap _trap EXIT

load_secret_driver "$SECRET_DRIVER"

# second key pairs
case "${2:-}" in
    --suffix | -r)
        if [ "$1" != "enc" ]; then
            echo "--suffix flag can be used only with enc command"
            exit 1
        fi
        # enc file suffix
        set $1 $4 $3
        ;;
esac

# first keys
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
        if [ "x" != "${3:-x}" ]; then
             enc "$2" "$3"
             break
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
        dirname "${SCRIPT_DIR}"
        break
        ;;
    downloader)
        # shellcheck source=scripts/commands/downloader.sh
        . "${SCRIPT_DIR}/commands/downloader.sh"

        downloader "$2" "$3" "$4" "$5"
        break
        ;;
    --help | -h | help)
        # shellcheck source=scripts/commands/help.sh
        . "${SCRIPT_DIR}/commands/help.sh"
        help_usage
        break
        ;;
    --driver | -d)
        load_secret_driver "$2"
        shift
        ;;
    --quiet | -q)
        # shellcheck disable=SC2034
        QUIET=true
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
