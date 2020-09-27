#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "template: helm template" {
    run helm secrets template
    assert_success
    assert_output --partial 'helm secrets template'
}

@test "template: helm template --help" {
    run helm secrets template --help
    assert_success
    assert_output --partial 'helm secrets template'
}

@test "template: helm template w/ chart" {
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial 'RELEASE-NAME-'
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + helm flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + pre decrypted secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    printf 'service:\n  port: 82' > "${FILE}.dec"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "port: 82"
    assert_file_exist "${FILE}.dec"

    run rm "${FILE}.dec"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + q flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -q template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + quiet flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --quiet template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + special path" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${SPECIAL_CHAR_DIR}"

    run helm secrets template "${SPECIAL_CHAR_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + invalid yaml" {
    FILE="${TEST_TEMP_DIR}/secrets.yaml"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Error: YAML parse error"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}
