#!/usr/bin/env bash

SOPS_VERSION="2.0.9"

RED='\033[0;31m'
GREEN='\033[0;32m'
#BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NOC='\033[0m'

HELM_WRAPPER="/usr/local/bin/helm-wrapper"

SOPS_DEB_URL="https://go.mozilla.org/sops/dist/sops_${SOPS_VERSION}_amd64.deb"
SOPS_DEB_SHA="fdc3559d6f16a54ec1d54d4a0aa1d7a3d273207ec78a37f9869dd2a1b32f5292"

if [ "$(uname)" == "Linux" ];
then
   LINUX_DISTRO="$(lsb_release -is)"
fi

### Mozilla SOPS binary install
if [ "$(uname)" == "Darwin" ];
then
        brew install sops
elif [ "$(uname)" == "Linux" ];
then
    if [ "${LINUX_DISTRO}" == "Ubuntu" ];
    then
        curl "${SOPS_DEB_URL}" > /tmp/sops.deb
        if [ "$(/usr/bin/shasum -a 256 /tmp/sops.deb | cut -d ' ' -f 1)" == "${SOPS_DEB_SHA}" ];
        then
            sudo dpkg -i /tmp/sops.deb;
        else
            echo -e "${RED}Wrong SHA256${NOC}"
        fi
    fi
else
    echo -e "${RED}No SOPS package available${NOC}"
    exit 1
fi

### git diff config
if [ -x "$(command -v git --version)" ];
then
    git config diff.sopsdiffer.textconv "sops -d"
else
    echo -e "${RED}[FAIL]${NOC} Install git command"
    exit 1
fi

### Helm-secrets wrapper for helm command with auto decryption and cleanup on the fly
echo ""
echo -ne "${YELLOW}*${NOC} Helm-secrets wrapper for helm binary: "
if [ -f "${HOME}/.helm/plugins/helm-secrets.git/wrapper.sh" ];
then
    ln -s "${HOME}"/.helm/plugins/helm-secrets.git/wrapper.sh ${HELM_WRAPPER} 2>/dev/null
elif [ -f "${HOME}/.helm/plugins/helm-secrets/wrapper.sh" ];
then
    ln -s "${HOME}"/.helm/plugins/helm-secrets/wrapper.sh ${HELM_WRAPPER} 2>/dev/null
fi

if [ -f ${HELM_WRAPPER} ];
then
    echo -e "${GREEN}${HELM_WRAPPER}${NOC}"
else
    echo -e "${RED}No ${HELM_WRAPPER} installed${NOC}"
fi
