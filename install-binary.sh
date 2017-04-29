#!/bin/bash

SOPS_VERSION="2.0.8"

HELM_WRAPPER="/usr/local/bin/helm-secrets"

SOPS_DEB_URL="https://go.mozilla.org/sops/dist/sops_${SOPS_VERSION}_amd64.deb"
SOPS_DEB_SHA="fdc3559d6f16a54ec1d54d4a0aa1d7a3d273207ec78a37f9869dd2a1b32f5292"

if [ "$(uname)" == "Linux" ];
then
   LINUX_DISTRO="$(lsb_release -is)"
fi

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
            echo "Wrong SHA256"
        fi
    fi
else
    echo "No SOPS package available"
    exit 1
fi

echo ""
echo -n "Helm-secrets wrapper for helm binary: "
if [ -f "${HOME}/.helm/plugins/helm-secrets.git/wrapper.sh" ];
then
    ln -s "${HOME}"/.helm/plugins/helm-secrets.git/wrapper.sh ${HELM_WRAPPER} 2>/dev/null
elif [ -f "${HOME}/.helm/plugins/helm-secrets/wrapper.sh" ];
then
    ln -s "${HOME}"/.helm/plugins/helm-secrets/wrapper.sh ${HELM_WRAPPER} 2>/dev/null
fi

if [ -f ${HELM_WRAPPER} ];
then
    echo ${HELM_WRAPPER}
else
    echo "No ${HELM_WRAPPER} installed"
fi
