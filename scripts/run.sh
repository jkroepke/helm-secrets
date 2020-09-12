#!/usr/bin/env sh

set -eu

# Path to current directory
SCRIPT_DIR="$(dirname "$0")"

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

file_dec_name() {
    if [ "${DEC_DIR}" != "" ]; then
        printf '%s' "${DEC_DIR}/$(basename "${1}" ".yaml")${DEC_SUFFIX}"
    else
        printf '%s' "$(dirname "${1}")/$(basename "${1}" ".yaml")${DEC_SUFFIX}"
    fi
}

load_secret_driver() {
    driver="${1}"
    if [ -f "${driver}" ]; then
        # Allow to load out of tree drivers.

        # shellcheck disable=SC1090
        . "${driver}"
    else
        if [ ! -f "${SCRIPT_DIR}/drivers/${driver}.sh" ]; then
            echo "Can't find secret driver: ${driver}"
            exit 1
        fi

        # shellcheck disable=SC1090
        . "${SCRIPT_DIR}/drivers/${driver}.sh"
    fi
}

load_secret_driver "$SECRET_DRIVER"

# ./run.sh vs bash run.sh
if [ "$(basename "$1")" == "run.sh" ]; then
    shift
fi

while true; do
    case "${1:-}" in
    enc)
        # shellcheck disable=SC1090
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
        # shellcheck disable=SC1090
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
        # shellcheck disable=SC1090
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
        # shellcheck disable=SC1090
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
        # shellcheck disable=SC1090
        . "${SCRIPT_DIR}/commands/clean.sh"

        if [ $# -lt 2 ]; then
            clean_usage
            echo "Error: Chart package required."
            exit 1
        fi
        clean "$2"
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
        # shellcheck disable=SC1090
        . "${SCRIPT_DIR}/commands/helm.sh"
        helm_command "$@"
        break
        ;;
    esac

    shift
done

exit 0
