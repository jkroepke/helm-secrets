#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "enc: helm enc" {
    run "${HELM_BIN}" secrets enc
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "enc: helm enc --help" {
    run "${HELM_BIN}" secrets enc --help
    assert_success
    assert_output --partial 'Encrypt secrets'
}

@test "enc: File not exits" {
    run "${HELM_BIN}" secrets enc nonexists
    assert_failure
    assert_output --partial '[helm-secrets] File does not exist: nonexists'
}

@test "enc: Encrypt secrets.yaml" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt some-secrets.yaml" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted some-secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt secrets.yaml.dec" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    cp "${VALUES_PATH}" "${VALUES_PATH}.dec"

    run "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted secrets.dec.yaml.dec to secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt secrets.yaml + special char directory name" {
    if ! is_driver "sops"; then
        skip
    fi

    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_PREFIX" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    DIR="$(dirname "${VALUES_PATH}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    HELM_SECRETS_DEC_SUFFIX=.dec

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_PREFIX:HELM_SECRETS_DEC_SUFFIX:${WSLENV:-}"

    cp "${VALUES_PATH}" "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted ${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX} to secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_SUFFIX" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    DIR="$(dirname "${VALUES_PATH}")"

    HELM_SECRETS_DEC_PREFIX=""
    HELM_SECRETS_DEC_SUFFIX=.test

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_PREFIX:HELM_SECRETS_DEC_SUFFIX:${WSLENV:-}"

    cp "${VALUES_PATH}" "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted ${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX} to secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_PREFIX + HELM_SECRETS_DEC_SUFFIX" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    DIR="$(dirname "${VALUES_PATH}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    HELM_SECRETS_DEC_SUFFIX=.foo

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DEC_PREFIX:HELM_SECRETS_DEC_SUFFIX:${WSLENV:-}"

    cp "${VALUES_PATH}" "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run env HELM_SECRETS_DEC_PREFIX="${HELM_SECRETS_DEC_PREFIX}" HELM_SECRETS_DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_output --partial "Encrypted ${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX} to secrets.dec.yaml"
    assert_success

    run "${HELM_BIN}" secrets view "${VALUES_PATH}"

    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
    assert_success
}

@test "enc: Encrypt secrets.tmp.yaml" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.tmp.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    YAML="hello: world"
    echo "${YAML}" > "${VALUES_PATH}"

    run "${HELM_BIN}" secrets enc "${VALUES_PATH}"

    assert_output -e "Encrypting.*${VALUES}"
    assert_success

    run "${HELM_BIN}" secrets dec "${VALUES_PATH}"

    assert_file_exists "${VALUES_PATH}.dec"
    assert_file_contains "${VALUES_PATH}.dec" 'hello: world'
    assert_success
}
