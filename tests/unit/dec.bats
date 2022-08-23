#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "dec: helm dec" {
    run "${HELM_BIN}" secrets dec
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "dec: helm dec --help" {
    run "${HELM_BIN}" secrets dec --help
    assert_output --partial 'Decrypt secrets'
    assert_success
}

@test "dec: File not exits" {
    run "${HELM_BIN}" secrets dec nonexists
    assert_failure
    assert_output --partial '[helm-secrets] File does not exist: nonexists'
}

@test "dec: Decrypt secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"
    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + quiet flag" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --quiet dec "${VALUES_PATH}"
    assert_success
    refute_output "[helm-secrets] Decrypting ${VALUES_PATH}"
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_QUIET" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_QUIET=true
    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_QUIET:${WSLENV:-}"

    run env HELM_SECRETS_QUIET="${HELM_SECRETS_QUIET}" WSLENV="${WSLENV:-}" "${HELM_BIN}" secrets dec "${VALUES_PATH}"
    assert_success
    refute_output "[helm-secrets] Decrypting ${VALUES_PATH}"
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml.gotpl" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml.gotpl"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"
    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_tpl'
}

@test "dec: Decrypt some-secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"
    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt values.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/values.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_output -e "\[helm-secrets\] File is not encrypted: .*${VALUES}"
    assert_failure
}

@test "dec: Decrypt secrets.yaml + special char directory name" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"
    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_PREFIX" {
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
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_secret: '
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_SUFFIX" {
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
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_secret: '
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_PREFIX + HELM_SECRETS_DEC_SUFFIX" {
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
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_secret: '
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_DIR" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_DEC_DIR="$(mktemp -d)"

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_DIR:${WSLENV:-}"

    run env HELM_SECRETS_DEC_DIR="${HELM_SECRETS_DEC_DIR}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
    assert_file_exists "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec"
    assert_file_contains "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" 'global_secret: '
    assert_file_contains "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" 'global_bar'

    temp_del "${HELM_SECRETS_DEC_DIR}"
}

@test "dec: Decrypt secrets.yaml + http://" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run "${HELM_BIN}" secrets dec "${VALUES}"
    assert_output -e "\[helm-secrets\] Decrypting .*${VALUES}"
    assert_success
}

@test "dec: Decrypt secrets.yaml + http://example.com/404.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="http://example.com/404.yaml"

    run "${HELM_BIN}" secrets dec "${VALUES}"
    assert_failure
    assert_output --partial "[helm-secrets] File does not exist: ${VALUES}"
}

@test "dec: Decrypt secrets.yaml + git://" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"

    run "${HELM_BIN}" secrets dec "${VALUES}"
    assert_output "[helm-secrets] Decrypting ${VALUES}"
    assert_success
}

@test "dec: Decrypt secrets.yaml + --backend-args (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --backend-args "--verbose" dec "${VALUES_PATH}"
    assert_output --partial "Data key recovered successfully"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + -a (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets -a "--verbose" dec "${VALUES_PATH}"
    assert_output --partial "Data key recovered successfully"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_BACKEND_ARGS (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_BACKEND_ARGS=--verbose

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + --backend-args (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --backend-args "--verbose --output-type \"yaml\"" dec "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + -a (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets -a "--verbose --output-type \"yaml\"" dec "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_BACKEND_ARGS (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_BACKEND_ARGS="--verbose --output-type \"yaml\""

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'global_secret: '
    assert_file_contains "${VALUES_PATH}.dec" 'global_bar'
}
