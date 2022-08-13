#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "gitops: Be silent inside ArgoCD" {
    if on_wsl || ! on_linux; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    env ARGOCD_APP_NAME=helm-secrets "${HELM_BIN}" lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" >"${TEST_TEMP_DIR}/output.helm.txt" 2>&1
    env ARGOCD_APP_NAME=helm-secrets "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" >"${TEST_TEMP_DIR}/output.secrets.txt" 2>&1

    run diff "${TEST_TEMP_DIR}/output.helm.txt" "${TEST_TEMP_DIR}/output.secrets.txt"
    assert_success

    rm -rf "${TEST_TEMP_DIR}/output.*.txt"
}
