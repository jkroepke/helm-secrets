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

# shellcheck source=scripts/lib/file.sh
. "${SCRIPT_DIR}/lib/file.sh"

# shellcheck source=scripts/lib/http.sh
. "${SCRIPT_DIR}/lib/http.sh"

_trap_hook() {
    true
}

_trap() {
    rm -rf "${TMPDIR}"

    _trap_hook
}

trap _trap EXIT

usage() {
    cat <<EOF
Secrets encryption in Helm Charts

This plugin provides ability to encrypt/decrypt secrets files
to store in less secure places, before they are installed using
Helm.

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

EOF
}

is_help() {
    case "$1" in
    -h | --help | help)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

load_secret_driver() {
    driver="${1}"
    if [ -f "${SCRIPT_DIR}/drivers/${driver}.sh" ]; then
        # shellcheck source=scripts/drivers/sops.sh
        . "${SCRIPT_DIR}/drivers/${driver}.sh"
    else
        # Allow to load out of tree drivers.
        if [ ! -f "${driver}" ]; then

            echo "Can't find secret driver: ${driver}"
            exit 1
        fi

        # shellcheck disable=SC2034
        HELM_SECRETS_SCRIPT_DIR="${SCRIPT_DIR}"

        # shellcheck source=tests/assets/custom-driver.sh
        . "${driver}"
    fi
}

load_secret_driver "$SECRET_DRIVER"

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
        usage
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
        usage
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
