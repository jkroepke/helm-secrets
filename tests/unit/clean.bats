#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "clean: helm clean" {
    run "${HELM_BIN}" secrets clean
    assert_failure
    assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: helm clean --help" {
    run "${HELM_BIN}" secrets clean --help
    assert_success
    assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: Directory not exits" {
    run "${HELM_BIN}" secrets clean nonexists
    assert_failure
    assert_output --partial 'Directory does not exist: nonexists'
}

@test "clean: Cleanup" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run "${HELM_BIN}" secrets dec "${FILE}"
    assert_success
    assert_file_exist "${FILE}.dec"

    run "${HELM_BIN}" secrets clean "$(dirname "${FILE}")"
    assert_file_not_exist "${FILE}.dec"
    assert_output --partial "${FILE}.dec"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_PREFIX" {
    if on_windows; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    DIR="$(dirname "${FILE}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    export HELM_SECRETS_DEC_PREFIX
    HELM_SECRETS_DEC_SUFFIX=
    export HELM_SECRETS_DEC_SUFFIX

    run "${HELM_BIN}" secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml"

    run "${HELM_BIN}" secrets clean "$(dirname "${FILE}")"
    assert_output --partial "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml"
    assert_file_not_exist "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_SUFFIX" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DEC_SUFFIX=.test
    export HELM_SECRETS_DEC_SUFFIX

    run "${HELM_BIN}" secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}${HELM_SECRETS_DEC_SUFFIX}"

    run "${HELM_BIN}" secrets clean "$(dirname "${FILE}")"
    assert_output --partial "${FILE}${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_not_exist "${FILE}${HELM_SECRETS_DEC_SUFFIX}"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_PREFIX + HELM_SECRETS_DEC_SUFFIX" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    DIR="$(dirname "${FILE}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    export HELM_SECRETS_DEC_PREFIX

    HELM_SECRETS_DEC_SUFFIX=.foo
    export HELM_SECRETS_DEC_SUFFIX

    run "${HELM_BIN}" secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run "${HELM_BIN}" secrets clean "$(dirname "${FILE}")"
    assert_output --partial "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_not_exist "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
}

@test "clean: Cleanup with custom name" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    run "${HELM_BIN}" secrets dec "${FILE}"
    assert_success
    assert_file_exist "${FILE}.dec"

    run "${HELM_BIN}" secrets clean "$(dirname "${FILE}")"
    assert_file_not_exist "${FILE}.dec"
    assert_output --partial "${FILE}.dec"
}
