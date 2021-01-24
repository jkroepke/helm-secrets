#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "upgrade: helm upgrade" {
    run helm secrets upgrade
    assert_success
    assert_output --partial 'helm secrets upgrade'
}

@test "upgrade: helm upgrade --help" {
    run helm secrets upgrade --help
    assert_success
    assert_output --partial 'helm secrets upgrade'
}

@test "upgrade: helm upgrade w/ chart" {
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial 'STATUS: deployed'
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 83"
}

@test "upgrade: helm upgrade w/ chart + some-secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 83"
}

@test "upgrade: helm upgrade w/ chart + some-secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 83"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + helm flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
}

@test "upgrade: helm upgrade w/ chart + pre decrypted secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    printf 'service:\n  port: 82' > "${FILE}.dec"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert [ -f "${FILE}.dec" ]

    run rm "${FILE}.dec"
    assert_success

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 82"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + q flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -q upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + quiet flag" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --quiet upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + special path" {
    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${SPECIAL_CHAR_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${SPECIAL_CHAR_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + invalid yaml" {
    FILE="${TEST_TEMP_DIR}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"

    create_encrypted_file 'replicaCount: |\n  a:'
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Error: YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + sops://" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "sops://${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + http://" {
    FILE="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: "
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm install w/ chart + secrets.yaml + git://" {
    if is_windows; then
        skip
    fi

    helm_plugin_install "git"
    FILE="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: "
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm upgrade w/ chart + secrets.yaml + secrets://http://" {
    FILE="secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "upgrade: helm install w/ chart + secrets.yaml + secrets://git://" {
    if is_windows; then
        skip
    fi

    helm_plugin_install "git"
    FILE="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"
    RELEASE="upgrade-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run helm upgrade -i "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}
