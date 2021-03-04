#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "gitops: Be silent inside ArgoCD" {
    export ARGOCD_APP_NAME=helm-secrets

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run diff <(helm lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1) <(helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1)
    assert_success
}
