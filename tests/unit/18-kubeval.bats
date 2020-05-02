#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "kubeval: helm plugin install helm-kubeval" {
    run helm plugin install https://github.com/instrumenta/helm-kubeval
    assert_success
}

@test "kubeval: helm kubeval" {
    run helm secrets kubeval
    assert_success
    assert_output --partial 'helm secrets kubeval'
}

@test "kubeval: helm kubeval --help" {
    run helm secrets kubeval --help
    assert_success
    assert_output --partial 'helm secrets kubeval'
}

@test "kubeval: helm kubeval w/ chart" {
    CHART=kubeval
    create_chart "${CHART}"

    run helm secrets kubeval "${TEST_DIR}/.tmp/${CHART}" --strict 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial 'The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount'
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "kubeval: helm kubeval w/ chart + secret file" {
    CHART=kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "kubeval: helm kubeval w/ chart + secret file + helm flag" {
    CHART=kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --set image.pullPolicy=Always --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "kubeval: helm kubeval w/ chart + pre decrypted secret file" {
    CHART=kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    printf 'podAnnotations:\n  secret: othervalue' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    create_chart "${CHART}"

    run helm secrets kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_file_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"

    run rm "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_success
}

@test "kubeval: helm kubeval w/ chart + secret file + q flag" {
    CHART=kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets -q kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --strict 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "kubeval: helm kubeval w/ chart + secret file + quiet flag" {
    CHART=kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets --quiet kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --strict 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount"
    refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "kubeval: helm kubeval w/ chart + secret file + special path" {
    # CHART="l§\\i'!&@\$n%t"
    # shellcheck disable=SC2016
    CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --strict 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "The file kubeval/templates/serviceaccount.yaml contains a valid ServiceAccount"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}

@test "kubeval: helm kubeval w/ chart + invalid yaml" {
    CHART=kubeval

    mkdir -p "${TEST_DIR}/.tmp/${CHART}" >&2
    printf 'replicaCount: |\n  a:' > "${TEST_DIR}/.tmp/${CHART}/secrets.yaml"

    create_chart "${CHART}"

    run helm secrets kubeval "${TEST_DIR}/.tmp/${CHART}" -f "${TEST_DIR}/.tmp/${CHART}/secrets.yaml" --strict 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml"
    assert_output --partial "Error: YAML parse error"
    assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
    assert_file_not_exist "${TEST_DIR}/.tmp/${CHART}/secrets.yaml.dec"
}
