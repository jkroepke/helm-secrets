#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "lint: helm lint" {
    run helm secrets lint
    assert_success
    assert_output --partial 'helm secrets lint'
}

@test "lint: helm lint --help" {
    run helm secrets lint --help
    assert_success
    assert_output --partial 'helm secrets lint'
}

@test "lint: helm lint w/ chart" {
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    assert_output --partial '1 chart(s) linted, 0 chart(s) failed'
}

@test "lint: helm lint w/ chart + secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + values.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/values.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + helm flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + helm flag + --" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint -f "${FILE}" --set service.type=NodePort -- "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + pre decrypted secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    printf 'service:\n  port: 82' > "${FILE}.dec"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_file_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + q flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -q lint "${TEST_TEMP_DIR}/chart" -f "${TEST_TEMP_DIR}/chart/values/${HELM_SECRETS_DRIVER}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_TEMP_DIR}/chart/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + quiet flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --quiet lint "${TEST_TEMP_DIR}/chart" -f "${TEST_TEMP_DIR}/chart/values/${HELM_SECRETS_DRIVER}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_TEMP_DIR}/chart/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + special path" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${SPECIAL_CHAR_DIR}"

    run helm secrets lint "${SPECIAL_CHAR_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + invalid yaml" {
    FILE="${TEST_TEMP_DIR}/secrets.yaml"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Error: 1 chart(s) linted, 1 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + --driver-args (simple)" {
    if ! is_driver_sops; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --driver-args "--verbose" lint "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --driver-args (simple)" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --driver-args "--verbose" lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + -a (simple)" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -a "--verbose" lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (simple)" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_DRIVER_ARGS=--verbose
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --driver-args (complex)" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --driver-args "--verbose --output-type \"yaml\"" lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + -a (complex)" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -a "--verbose --output-type \"yaml\"" lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (complex)" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2089
    HELM_SECRETS_DRIVER_ARGS="--verbose --output-type \"yaml\""
    # shellcheck disable=SC2090
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets lint "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}
