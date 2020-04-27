#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "install: helm install" {
    run helm secrets install
    assert_success
    assert_output --partial 'helm secrets install'
}

@test "install: helm install --help" {
    run helm secrets install --help
    assert_success
    assert_output --partial 'helm secrets install'
}

@test "install: helm install w/ chart" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"
    create_chart "${CHART}"

    run helm secrets install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial 'STATUS: deployed'
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + secret file" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + secret file + helm flag" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --set image.pullPolicy=Always 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + pre decrypted secret file" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    printf 'podAnnotations:\n  secret: othervalue' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    create_chart "${CHART}"

    run helm secrets install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert [ -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run rm "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_success

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: othervalue"

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + secret file + q flag" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets -q install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + secret file + quiet flag" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets --quiet install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + secret file + special path" {
    # shellcheck disable=SC2016
    CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/install
    RELEASE="${CHART#*/}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run kubectl get pods -o yaml -l "app.kubernetes.io/name=install,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "secret: value"

    run helm del "${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + invalid yaml" {
    CHART=install
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'replicaCount: |\n  a:' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets install "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" --no-hooks -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "Error: YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}
