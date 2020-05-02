#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "kubeval: helm plugin install helm-diff" {
    run helm plugin install https://github.com/databus23/helm-diff
    assert_success
}

@test "diff: helm install" {
    run helm secrets diff
    assert_success
    assert_output --partial 'helm secrets diff'
}

@test "diff: helm diff upgrade --help" {
    run helm secrets diff --help
    assert_success
    assert_output --partial 'helm secrets diff'
}

@test "diff: helm diff upgrade w/ chart" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"
    create_chart "${CHART}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "Release was not present in Helm."
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secret file" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "secret: value"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secret file + helm flag" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --set image.pullPolicy=Always 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "imagePullPolicy: Always"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}

@test "diff: helm diff upgrade w/ chart + pre decrypted secret file" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    printf 'podAnnotations:\n  secret: othervalue' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    create_chart "${CHART}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "secret: othervalue"
    assert [ -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]

    run rm "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_success
}

@test "diff: helm diff upgrade w/ chart + secret file + q flag" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets -q diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "secret: value"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secret file + quiet flag" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets --quiet diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "secret: value"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}

@test "diff: helm diff upgrade w/ chart + secret file + special path" {
    # shellcheck disable=SC2016
    CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/diff
    RELEASE="${CHART#*/}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "secret: value"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}

@test "diff: helm diff upgrade w/ chart + invalid yaml" {
    CHART="diff"
    RELEASE="${CHART}-$(date +%s)-${RANDOM}"

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'replicaCount: |\n  a:' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets diff upgrade --no-color --allow-unreleased "${RELEASE}" "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "Error: YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert [ ! -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec" ]
}
