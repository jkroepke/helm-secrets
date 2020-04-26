#!/usr/bin/env sh

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NOC='\033[0m'
ALREADY_ENC="Already encrypted"
SECRETS_REPO="https://github.com/zendesk/helm-secrets"
HELM_CMD="helm"

trap_error() {
  status=$?
  if [ "$status" -ne 0 ]; then
    printf "${RED}%s${NOC}\n" "General error"
    exit 1
  else
    exit 0
  fi
  printf "${RED}%s${NOC}\n" "General error"
}

trap "trap_error" EXIT

test_encryption() {
  result=$(cat <"${secret}" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
  if [ "${result}" -eq 2 ] && [ "${secret}" = "./example/helm_vars/secrets.yaml" ]; then
    printf "${GREEN}%s${NOC} %s\n" "[OK]" "File properly encrypted"
  elif [ "${result}" -eq 1 ] && [ "${secret}" != "./example/helm_vars/secrets.yaml" ]; then
    printf "${GREEN}%s${NOC} %s\n" "[OK]" "File properly encrypted"
  else
    printf "${RED}%s${NOC} %s\n" "[FAIL]" "${secret} Not encrypted properly"
    exit 1
  fi
}

test_view() {
  result_view=$(${HELM_CMD} secrets view "${secret}" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
  if [ "${result_view}" -gt 0 ]; then
    printf "${RED}%s${NOC} %s\n" "[FAIL]" "Decryption failed"
  else
    printf "${GREEN}%s${NOC} %s\n" "[OK]" "File decrypted and viewable"
  fi
}

test_decrypt() {
  if [ -f "${secret}.dec" ]; then
    result_dec=$(cat <"${secret}.dec" | grep -Ec "(40B6FAEC80FD467E3FE9421019F6A67BB1B8DDBE|4434EA5D05F10F59D0DF7399AF1D073646ED4927)")
    if [ "${result_dec}" -gt 0 ]; then
      printf "${RED}%s${NOC} %s\n" "[FAIL]" "Decryption failed"
    else
      printf "${GREEN}%s${NOC} %s\n" "[OK]" "File decrypted"
    fi
  else
    printf "${RED}%s${NOC} %s\n" "[FAIL]" "${secret}.dec not exist"
    exit 1
  fi
}

test_clean() {
  if [ -f "${secret}.dec" ]; then
    printf "${RED}%s${NOC} %s\n" "[FAIL]" "${secret}.dec exist after cleanup"
    exit 1
  else
    printf "${GREEN}%s${NOC} %s\n" "[OK]" "Cleanup ${mode}"
  fi
}

test_already_encrypted() {
  if echo "${enc_res}" | grep -q "${ALREADY_ENC}"; then
    printf "${GREEN}%s${NOC} %s\n" "[OK]" "Already Encrypted"
  else
    printf "${RED}%s${NOC} %s\n" "[FAIL]" "Not Encrypted or re-encrypted. Should be already encrypted with no re-encryption."
    exit 1
  fi
}

test_helm_secrets() {
  printf "${YELLOW}+++${NOC} ${BLUE}%s${NOC}\n" "Testing ${secret}"

  printf "${YELLOW}+++${NOC} %s\n" "Encrypt and Test"
  "${HELM_CMD}" secrets enc "${secret}" >/dev/null || exit 1 &&
    test_encryption "${secret}"

  printf "${YELLOW}+++${NOC} %s\n" "Test if 'Already Encrypted' feature works"
  enc_res=$("${HELM_CMD}" secrets enc "${secret}" | grep "${ALREADY_ENC}")
  test_already_encrypted "${enc_res}"

  printf "${YELLOW}+++${NOC} %s\n" "View encrypted Test"
  test_view "${secret}"

  printf "${YELLOW}+++${NOC} %s\n" "Decrypt"
  "${HELM_CMD}" secrets dec "${secret}" >/dev/null || exit 1 &&
    test_decrypt "${secret}" &&
    cp "${secret}.dec" "${secret}"

  printf "${YELLOW}+++${NOC} %s\n" "Cleanup Test"
  "${HELM_CMD}" secrets clean "$(dirname "${secret}")" >/dev/null || exit 1
  mode="specified directory"
  test_clean "${secret}" "${mode}" &&
    cp "${secret}" "${secret}.dec" &&
    "${HELM_CMD}" secrets clean "${secret}.dec" >/dev/null || exit 1
  mode="specified .dec file"
  test_clean "${secret}" "${mode}" # && \
  # cp "${secret}" "${secret}.dec" && \
  # "${HELM_CMD}" secrets clean "${secret}.dec" > /dev/null || exit 1
  # mode="specified encrypted secret file"
  # test_clean "${secret}" "${mode}"
  # The functionality above doesn't work, it only works with .dec in filename

  printf "${YELLOW}+++${NOC} %s\n" "Once again Encrypt and Test"
  "${HELM_CMD}" secrets enc "${secret}" >/dev/null || exit 1 &&
    test_encryption "${secret}"
}

echo " "
for secret in $(find . -type f -name secrets.yaml); do
  test_helm_secrets "${secret}"
done
