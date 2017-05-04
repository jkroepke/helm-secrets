#!/bin/bash

test_encryption() {
result=$(cat < "${secret}" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
if [ "${result}" -eq 2 ] && [ "${secret}" == "./example/helm_vars/secrets.yaml" ];
then
    echo "[OK] File properly encrypted"
elif [ "${result}" -eq 1 ] && [ "${secret}" != "./example/helm_vars/secrets.yaml" ];
then
    echo "[OK] File properly encrypted"
else
    echo "[FAIL] ${secret} Not encrypted properly"
    exit 1
fi
}

test_view() {
result_view=$(helm-wrapper secrets view "${secret}" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
if [ "${result_view}" -gt 0 ];
then
    echo "[FAIL] Decryption failed"
else
    echo "[OK] File decrypted"
fi
}

test_decrypt() {
if [ -f "${secret}.dec" ];
then
    result_dec=$(cat < "${secret}.dec" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
    if [ "${result_dec}" -gt 0 ];
    then
        echo "[FAIL] Decryption failed"
    else
        echo "[OK] File decrypted"
    fi
else
    echo "[FAIL] ${secret}.dec not exist"
    exit 1
fi
}

test_helm_secrets() {
echo "+++ Testing ${secret}"
echo "+++ Encrypt and Test"
helm-wrapper secrets enc "${secret}" 2>&1 >/dev/null && \
test_encryption "${secret}"
echo "+++ View encrypted test"
test_view "${secret}"
echo "+++ Decrypt"
helm-wrapper secrets dec "${secret}" 2>&1 >/dev/null && \
test_decrypt "${secret}" && \
mv "${secret}.dec" "${secret}"
echo "+++ Once again Encrypt and Test"
helm-wrapper secrets enc "${secret}" 2>&1 >/dev/null && \
test_encryption "${secret}"
}

echo "+++ Installing helm-secrets plugin"
if [ "$(helm plugin list | tail -n1 | cut -d ' ' -f 1 | grep -c "secrets")" -eq 1 ];
then
    echo "[OK] helm-ecrets plugin installed"
else
    helm plugin install https://github.com/futuresimple/helm-secrets 2>/dev/null
    echo "[FAIL] No helm-secrets plugin aboting"
    exit 1
fi

echo ""
if [ -x "$(command -v gpg --version)" ];
then
    echo "+++ Importing private pgp key for projectx"
    gpg --import example/pgp/projectx.asc
    echo ""
    echo "+++ Importing private pgp key for projectx"
    gpg --import example/pgp/projecty.asc
    echo ""
else
    echo "Install gpg"
    exit 1
fi

echo "+++ Show helm_vars tree from example"
if [ -x "$(command -v tree --version)" ];
then
    tree -Ca example/helm_vars/
else
    echo "Install tree command"
    exit 1
fi

echo ""
for secret in $(find . -type f -name secrets.yaml);
do test_helm_secrets "${secret}";
done
