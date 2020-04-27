#!/usr/bin/env sh

set -eu

SOPS_VERSION="v3.5.0"
SOPS_LINUX_URL="https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux"
SOPS_LINUX_SHA="610fca9687d1326ef2e1a66699a740f5dbd5ac8130190275959da737ec52f096"

RED='\033[0;31m'
#GREEN='\033[0;32m'
#BLUE='\033[0;34m'
#YELLOW='\033[1;33m'
NOC='\033[0m'

download() {
    if command -v curl >/dev/null; then
        curl -sSfL "$1"
    elif command -v wget >/dev/null; then
        wget -q -O- "$1"
    else
        return 1
    fi
}

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
if command -v git 2>/dev/null; then
    git config --global diff.sopsdiffer.textconv "sops -d"
fi
