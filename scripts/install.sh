#!/usr/bin/env sh

set -eu

# Path to current directory
SCRIPT_DIR="$(dirname "$0")"

# shellcheck source=scripts/lib/http.sh
. "${SCRIPT_DIR}/lib/http.sh"

SOPS_DEFAULT_VERSION="v3.6.1"
SOPS_VERSION="${SOPS_VERSION:-$SOPS_DEFAULT_VERSION}"
SOPS_LINUX_URL="${SOPS_LINUX_URL:-"https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux"}"
SOPS_LINUX_SHA="${SOPS_LINUX_SHA:-"b2252aa00836c72534471e1099fa22fab2133329b62d7826b5ac49511fcc8997"}"

RED='\033[0;31m'
#GREEN='\033[0;32m'
#BLUE='\033[0;34m'
#YELLOW='\033[1;33m'
NOC='\033[0m'

get_sha_256() {
    if command -v sha256sum >/dev/null; then
        res=$(sha256sum "$1")
    elif command -v shasum >/dev/null; then
        res=$(shasum -a 256 "$1")
    else
        res=''
    fi

    echo "$res" | cut -d ' ' -f 1
}

if [ -n "${SKIP_SOPS_INSTALL+x}" ] && [ "${SKIP_SOPS_INSTALL}" = "true" ]; then
    echo "Skipping sops installation."
elif command -v sops >/dev/null; then
    printf "sops is already installed: "
    sops --version
else
    # Try to install sops.
    if [ "$(uname)" = "Darwin" ] && command -v brew >/dev/null; then
        brew install sops
    elif [ "$(uname)" = "Linux" ]; then
        if ! download "${SOPS_LINUX_URL}" >/tmp/sops; then
            printf "${RED}%s${NOC}\n" "Can't download SOPS ..."
            echo "Ignoring ..."
        else
            SOPS_SHA256="$(get_sha_256 /tmp/sops)"
            if [ "${SOPS_SHA256}" = "${SOPS_LINUX_SHA}" ] || [ "${SOPS_SHA256}" = "" ]; then
                chmod +x /tmp/sops
                if [ -w "/usr/local/bin/" ]; then
                    mv /tmp/sops /usr/local/bin/
                else
                    printf "${RED}%s${NOC}\n" "/usr/local/bin/ is not writable"
                    echo "Ignoring ..."
                fi
            else
                printf "${RED}%s${NOC}\n" "Checksum mismatch"
                if [ "${SOPS_VERSION}" != "${SOPS_DEFAULT_VERSION}" ]; then
                    printf "${RED}%s${NOC}\n" "Forgot to set SOPS_LINUX_SHA?"
                fi
                echo "Ignoring ..."
            fi
            rm -f /tmp/sops
        fi
    else
        printf "${RED}%s${NOC}\n" "No SOPS package available"
        exit 1
    fi
fi

# If git is no available, fail silent.
if command -v git >/dev/null; then
    git config --global diff.sopsdiffer.textconv "sops -d"
fi
