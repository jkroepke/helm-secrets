#!/usr/bin/env bats

load '../helper'
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
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"
    create_chart "${CHART}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial 'STATUS: deployed'
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + secret file" {
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + secret file + helm flag" {
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --set image.pullPolicy=Always 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + pre decrypted secret file" {
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    printf 'podAnnotations:\n  secret: othervalue' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    create_chart "${CHART}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert [ -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run rm "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_success

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: othervalue"

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + secret file + q flag" {
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets -q upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + secret file + quiet flag" {
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets --quiet upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + secret file + special path" {
    # shellcheck disable=SC2016
    CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/upgrade
    RELEASE="${CHART#*/}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get deploy -o yaml -l "app.kubernetes.io/name=upgrade,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "upgrade: helm upgrade w/ chart + invalid yaml" {
    CHART="upgrade"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'replicaCount: |\n  a:' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets upgrade -i "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "Error: YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}
