#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NOC='\033[0m'
SECRETS_REPO="https://github.com/futuresimple/helm-secrets"

test_encryption() {
result=$(cat < "${secret}" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
if [ "${result}" -eq 2 ] && [ "${secret}" == "./example/helm_vars/secrets.yaml" ];
then
    echo -e "${GREEN}[OK]${NOC} File properly encrypted"
elif [ "${result}" -eq 1 ] && [ "${secret}" != "./example/helm_vars/secrets.yaml" ];
then
    echo -e "${GREEN}[OK]${NOC} File properly encrypted"
else
    echo -e "${RED}[FAIL]${NOC} ${secret} Not encrypted properly"
    exit 1
fi
}

test_view() {
result_view=$(helm-wrapper secrets view "${secret}" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
if [ "${result_view}" -gt 0 ];
then
    echo -e "${RED}[FAIL]${NOC} Decryption failed"
else
    echo -e "${GREEN}[OK]${NOC} File decrypted and viewable"
fi
}

test_decrypt() {
if [ -f "${secret}.dec" ];
then
    result_dec=$(cat < "${secret}.dec" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
    if [ "${result_dec}" -gt 0 ];
    then
        echo -e "${RED}[FAIL]${NOC} Decryption failed"
    else
        echo -e "${GREEN}[OK]${NOC} File decrypted"
    fi
else
    echo -e "${RED}[FAIL]${NOC} ${secret}.dec not exist"
    exit 1
fi
}

test_clean() {
if [ -f "${secret}.dec" ];
then
    echo -e "${RED}[FAIL]${NOC} ${secret}.dec exist after cleanup"
    exit 1
else
    echo -e "${GREEN}[OK]${NOC} Cleanup ${mode}"
fi
}

test_helm_secrets() {
echo -e "${YELLOW}+++${NOC} ${BLUE}Testing ${secret}${NOC}"
echo -e "${YELLOW}+++${NOC} Encrypt and Test"
helm-wrapper secrets enc "${secret}" 2>&1 >/dev/null && \
test_encryption "${secret}"
echo -e "${YELLOW}+++${NOC} View encrypted Test"
test_view "${secret}"
echo -e "${YELLOW}+++${NOC} Decrypt"
helm-wrapper secrets dec "${secret}" 2>&1 >/dev/null && \
test_decrypt "${secret}" && \
cp "${secret}.dec" "${secret}"
echo -e "${YELLOW}+++${NOC} Cleanup Test"
helm-wrapper secrets clean "$(dirname ${secret})" 2>&1 >/dev/null && \
mode="directory"
test_clean "${secret}" "${mode}" && \
cp "${secret}" "${secret}.dec" && \
helm-wrapper secrets clean "${secret}.dec" 2>&1 >/dev/null && \
mode="specified .dec file"
test_clean "${secret}" "${mode}"
echo -e "${YELLOW}+++${NOC} Once again Encrypt and Test"
helm-wrapper secrets enc "${secret}" 2>&1 >/dev/null && \
test_encryption "${secret}"
}

echo -e "${YELLOW}+++${NOC} Installing helm-secrets plugin"
if [ "$(helm plugin list | tail -n1 | cut -d ' ' -f 1 | grep -c "secrets")" -eq 1 ];
then
    echo -e "${GREEN}[OK]${NOC} helm-ecrets plugin installed"
else
    helm plugin install "${SECRETS_REPO}" 2>/dev/null
    echo -e "${RED}[FAIL]${NOC} No helm-secrets plugin aboting"
    exit 1
fi

echo ""
if [ -x "$(command -v gpg --version)" ];
then
    echo -e "${YELLOW}+++${NOC} Importing private pgp key for projectx"
    gpg --import example/pgp/projectx.asc
    echo ""
    echo -e "${YELLOW}+++${NOC} Importing private pgp key for projectx"
    gpg --import example/pgp/projecty.asc
    echo ""
else
    echo -e "${RED}[FAIL]${NOC} Install gpg"
    exit 1
fi

echo -e "${YELLOW}+++${NOC} Show helm_vars tree from example"
if [ -x "$(command -v tree --version)" ];
then
    tree -Ca example/helm_vars/
else
    echo -e "${RED}[FAIL]${NOC} Install tree command"
    exit 1
fi

echo ""
for secret in $(find . -type f -name secrets.yaml);
do test_helm_secrets "${secret}";
done
