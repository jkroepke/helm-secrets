#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "diff: helm install" {
    helm_plugin_install "diff"

    run helm secrets diff
    assert_success
    assert_output --partial 'helm secrets diff'
}

@test "diff: helm diff upgrade --help" {
    helm_plugin_install "diff"

    run helm secrets diff --help
    assert_success
    assert_output --partial 'helm secrets diff'
}

@test "diff: helm diff upgrade w/ chart" {
    helm_plugin_install "diff"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Release was not present in Helm."
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + some-secrets.yaml" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + helm flag" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + pre decrypted secrets.yaml" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    printf 'service:\n  port: 82' > "${FILE}.dec"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "port: 82"
    assert [ -f "${FILE}.dec" ]

    run rm "${FILE}.dec"
    assert_success
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + q flag" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -q diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + quiet flag" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --quiet diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secrets.yaml + special path" {
    helm_plugin_install "diff"
    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_chart "${SPECIAL_CHAR_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${SPECIAL_CHAR_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "diff: helm diff upgrade w/ chart + invalid yaml" {
    helm_plugin_install "diff"
    FILE="${TEST_TEMP_DIR}/secrets.yaml"
    RELEASE="diff-$(date +%s)-${SEED}"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Error: YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}
