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
    assert_output --partial 'Clean all decrypted files if any exist'
    assert_success
}

@test "clean: Directory not exits" {
    run "${HELM_BIN}" secrets clean nonexists
    assert_failure
    assert_output --partial 'Directory does not exist: nonexists'
}

@test "clean: Cleanup" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"

    run "${HELM_BIN}" secrets clean "$(dirname "${VALUES_PATH}")"

    assert_output --partial "${VALUES}.dec"
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_PREFIX" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    DIR="$(dirname "${VALUES_PATH}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    HELM_SECRETS_DEC_SUFFIX=.dec
    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_PREFIX:HELM_SECRETS_DEC_SUFFIX:${WSLENV:-}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets clean "$(dirname "${VALUES_PATH}")"

    assert_output --partial "${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_not_exists "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_SUFFIX" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    DIR="$(dirname "${VALUES_PATH}")"

    HELM_SECRETS_DEC_PREFIX=
    HELM_SECRETS_DEC_SUFFIX=.test
    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_PREFIX:HELM_SECRETS_DEC_SUFFIX:${WSLENV:-}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets clean "$(dirname "${VALUES_PATH}")"

    assert_output --partial "${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_not_exists "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
}

@test "clean: Cleanup with HELM_SECRETS_DEC_PREFIX + HELM_SECRETS_DEC_SUFFIX" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    DIR="$(dirname "${VALUES_PATH}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    HELM_SECRETS_DEC_SUFFIX=.foo
    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_PREFIX:HELM_SECRETS_DEC_SUFFIX:${WSLENV:-}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets clean "$(dirname "${VALUES_PATH}")"

    assert_output --partial "${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_not_exists "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
}

@test "clean: Cleanup with custom name" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"

    run "${HELM_BIN}" secrets clean "$(dirname "${VALUES_PATH}")"
    assert_output --partial "${VALUES}.dec"
    assert_file_not_exists "${VALUES_PATH}.dec"
}
