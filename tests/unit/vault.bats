#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "vault: fail on error" {
    if [ "${HELM_SECRETS_DRIVER}" != "vault" ]; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run env VAULT_ADDR= helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "Error while get secret from vault!"
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_output --partial "Error: plugin \"secrets\" exited with error"
    assert_file_not_exist "${FILE}.dec"
}

@test "vault: cleanup temporary files" {
    if [ "${HELM_SECRETS_DRIVER}" != "vault" ]; then
        skip
    fi

    export HELM_SECRETS_DEC_TMP_DIR="${TMPDIR:-"/tmp/"}helm-secrets.$$"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"

    assert_dir_not_exist "${HELM_SECRETS_DEC_TMP_DIR}"
}
