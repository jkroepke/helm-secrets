#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "kubeval: helm kubeval" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    run helm secrets kubeval
    assert_success
    assert_output --partial 'helm secrets kubeval'
}

@test "kubeval: helm kubeval --help" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    run helm secrets kubeval --help
    assert_success
    assert_output --partial 'helm secrets kubeval'
}

@test "kubeval: helm kubeval w/ chart" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" --strict 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial 'The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount'
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml + --values" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" --values "${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml + --values=" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" --values="${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + some-secrets.yaml" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + some-secrets.yaml + --values" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" --values "${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + some-secrets.yaml + --values=" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" --values="${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml + helm flag" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --set service.type=NodePort --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + pre decrypted secrets.yaml" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    printf 'service:\n  port: 82' > "${FILE}.dec"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_file_exist "${FILE}.dec"

    run rm "${FILE}.dec"
    assert_success
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml + q flag" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -q kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml + quiet flag" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --quiet kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + secrets.yaml + special path" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${SPECIAL_CHAR_DIR}"

    run helm secrets kubeval "${SPECIAL_CHAR_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "The file chart/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "kubeval: helm kubeval w/ chart + invalid yaml" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    helm_plugin_install "kubeval"

    FILE="${TEST_TEMP_DIR}/secrets.yaml"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets kubeval "${TEST_TEMP_DIR}/chart" -f "${FILE}" --strict 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Error: YAML parse error"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}
