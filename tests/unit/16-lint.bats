#!/usr/bin/env bats

load '../helper'
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
    CHART=lint
    create_chart "${CHART}"

    run helm secrets lint "${TEST_DIR}/.tmp/${CHART}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial '1 chart(s) linted, 0 chart(s) failed'
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "lint: helm lint w/ chart + secret file" {
    CHART=lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "lint: helm lint w/ chart + secret file + helm flag" {
    CHART=lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --set image.pullPolicy=Always 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "lint: helm lint w/ chart + pre decrypted secret file" {
    CHART=lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    printf 'podAnnotations:\n  secret: othervalue' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    create_chart "${CHART}"

    run helm secrets lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_file_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    run rm "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_success
}

@test "lint: helm lint w/ chart + secret file + q flag" {
    CHART=lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets -q lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "lint: helm lint w/ chart + secret file + quiet flag" {
    CHART=lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets --quiet lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "lint: helm lint w/ chart + secret file + special path" {
    # CHART="l§\\i'!&@\$n%t"
    # shellcheck disable=SC2016
    CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "lint: helm lint w/ chart + invalid yaml" {
    CHART=lint

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'replicaCount: |\n  a:' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets lint "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "Error: 1 chart(s) linted, 1 chart(s) failed"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}
