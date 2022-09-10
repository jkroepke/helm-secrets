#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "encrypt: helm encrypt" {
    run "${HELM_BIN}" secrets encrypt
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "encrypt: helm encrypt --help" {
    run "${HELM_BIN}" secrets encrypt --help
    assert_success
    assert_output --partial 'Encrypt secrets'
}

@test "encrypt: File not exits" {
    run "${HELM_BIN}" secrets encrypt nonexists
    assert_failure
    assert_output --partial '[helm-secrets] File does not exist: nonexists'
}

@test "encrypt: Encrypt secrets.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets encrypt "${VALUES_PATH}"

    assert_output --partial 'global_secret: ENC'
    assert_success
}

@test "encrypt: Encrypt inline secrets.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" --debug secrets encrypt -i "${VALUES_PATH}"
    refute_output --regex '.+'
    assert_success

    assert_file_contains "${VALUES_PATH}" 'global_secret: ENC'

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "encrypt: Encrypt some-secrets.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets encrypt "${VALUES_PATH}"

    assert_output --partial 'global_secret: ENC'
    assert_success
}

@test "encrypt: Encrypt secrets.yaml + special char directory name" {
    if ! is_backend "sops"; then
        skip
    fi

    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.dec.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets encrypt "${VALUES_PATH}"

    assert_output --partial 'global_secret: ENC'
    assert_success
}

@test "encrypt: Encrypt secrets.tmp.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.tmp.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    YAML="hello: world"
    echo "${YAML}" >"${VALUES_PATH}"

    run "${HELM_BIN}" secrets encrypt -i "${VALUES_PATH}"
    assert_success

    run "${HELM_BIN}" secrets decrypt -i "${VALUES_PATH}"

    assert_file_exists "${VALUES_PATH}"
    assert_file_contains "${VALUES_PATH}" 'hello: world'
    assert_success
}
