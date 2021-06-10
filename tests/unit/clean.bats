#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "clean: helm clean" {
    run helm secrets clean
    assert_failure
    assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: helm clean --help" {
    run helm secrets clean --help
    assert_success
    assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: Directory not exits" {
    run helm secrets clean nonexists
    assert_failure
    assert_output --partial 'Directory does not exist: nonexists'
}

@test "clean: Cleanup" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_file_exist "${FILE}.dec"

    run helm secrets clean "$(dirname "${FILE}")"
    assert_file_not_exist "${FILE}.dec"
    assert_output --partial "${FILE}.dec"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_SUFFIX" {
    HELM_SECRETS_DEC_SUFFIX=.test
    export HELM_SECRETS_DEC_SUFFIX

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_file_exist "${FILE}.test"

    run helm secrets clean "$(dirname "${FILE}")"
    assert_file_not_exist "${FILE}.test"
    assert_output --partial "${FILE}.test"
}

@test "clean: Cleanup with custom name" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_file_exist "${FILE}.dec"

    run helm secrets clean "$(dirname "${FILE}")"
    assert_file_not_exist "${FILE}.dec"
    assert_output --partial "${FILE}.dec"
}
