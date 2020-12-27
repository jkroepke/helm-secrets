#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "dec: helm dec" {
    run helm secrets dec
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "dec: helm dec --help" {
    run helm secrets dec --help
    assert_success
    assert_output --partial 'Decrypt secrets'
}

@test "dec: File not exits" {
    run helm secrets dec nonexists
    assert_failure
    assert_output --partial 'File does not exist: nonexists'
}

@test "dec: Decrypt secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: Decrypt some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: Decrypt values.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/values.yaml"

    run helm secrets dec "${FILE}"
    assert_failure
    assert_output --partial "[helm-secrets] Decrypting ${FILE}"
    assert_output --partial "[helm-secrets] File is not encrypted: ${FILE}"
}

@test "dec: Decrypt secrets.yaml + special char directory name" {
    if is_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_SUFFIX" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DEC_SUFFIX=.yaml.test
    export HELM_SECRETS_DEC_SUFFIX

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.test"
    assert_file_contains "${FILE}.test" 'global_secret: '
    assert_file_contains "${FILE}.test" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_DIR" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DEC_DIR="$(mktemp -d)"
    export HELM_SECRETS_DEC_DIR

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec"
    assert_file_contains "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" 'global_secret: '
    assert_file_contains "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + http://" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="https://raw.githubusercontent.com/jkroepke/helm-secrets/master/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
}

@test "dec: Decrypt secrets.yaml + http://example.com/404.yaml" {
    if ! is_driver_sops; then
        skip
    fi

    FILE="http://example.com/404.yaml"

    run helm secrets dec "${FILE}"
    assert_failure
    assert_output --partial "[helm-secrets] File does not exist: ${FILE}"
}

@test "dec: Decrypt secrets.yaml + git://" {
    if ! is_driver_sops || is_windows; then
        skip
    fi

    helm_plugin_install "git"
    FILE="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=master"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
}
