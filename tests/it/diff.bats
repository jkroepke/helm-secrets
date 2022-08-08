#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "diff: helm install" {
    run "${HELM_BIN}" secrets diff
    assert_success
    assert_output --partial 'helm secrets [ OPTIONS ] diff'
}

@test "diff: helm diff upgrade --help" {
    run "${HELM_BIN}" secrets diff --help
    assert_success
    assert_output --partial 'helm secrets [ OPTIONS ] diff'
}

@test "diff: helm diff upgrade w/ chart" {
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt:"
    assert_output --partial "Release was not present in Helm."
    refute_output --partial "[helm-secrets] Removed:"
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + some-secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + some-secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + helm flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + pre decrypted secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    printf 'service:\n  port: 82' >"${FILE}.dec"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "port: 82"
    assert [ -f "${FILE}.dec" ]

    run rm "${FILE}.dec"
    assert_success
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + q flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -q diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + quiet flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --quiet diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + special path" {
    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${SPECIAL_CHAR_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${SPECIAL_CHAR_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + invalid yaml" {
    FILE="${TEST_TEMP_DIR}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + sops://" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "sops://${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + http://" {
    FILE="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm install w/ chart + secrets.yaml + git://" {
    if on_windows; then
        skip
    fi

    FILE="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + secrets://http://" {
    FILE="secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm install w/ chart + secrets.yaml + secrets://git://" {
    if on_windows; then
        skip
    fi

    FILE="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
    assert [ ! -f "${FILE}.dec" ]
}
