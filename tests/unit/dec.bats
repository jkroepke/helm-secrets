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
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml.gotpl" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml.gotpl"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_tpl'
}

@test "dec: Decrypt some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: Decrypt values.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/values.yaml"

    run helm secrets dec "${FILE}"

    assert_failure
    assert_output --partial "[helm-secrets] Decrypting ${FILE}"
    assert_output --partial "[helm-secrets] File is not encrypted: ${FILE}"
}

@test "dec: Decrypt secrets.yaml + special char directory name" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_PREFIX" {
    if on_windows; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    DIR="$(dirname "${FILE}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    export HELM_SECRETS_DEC_PREFIX
    HELM_SECRETS_DEC_SUFFIX=
    export HELM_SECRETS_DEC_SUFFIX

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml"
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml" 'global_secret: '
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_SUFFIX" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DEC_SUFFIX=.test
    export HELM_SECRETS_DEC_SUFFIX

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${FILE}${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_contains "${FILE}${HELM_SECRETS_DEC_SUFFIX}" 'global_secret: '
    assert_file_contains "${FILE}${HELM_SECRETS_DEC_SUFFIX}" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_PREFIX + HELM_SECRETS_DEC_SUFFIX" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    DIR="$(dirname "${FILE}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    export HELM_SECRETS_DEC_PREFIX
    HELM_SECRETS_DEC_SUFFIX=.foo
    export HELM_SECRETS_DEC_SUFFIX

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}"
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_secret: '
    assert_file_contains "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.yaml${HELM_SECRETS_DEC_SUFFIX}" 'global_bar'
}

@test "dec: Decrypt secrets.yaml + HELM_SECRETS_DEC_DIR" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DEC_DIR="$(_mktemp -d)"
    export HELM_SECRETS_DEC_DIR

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
    assert_file_exist "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec"
    assert_file_contains "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" 'global_secret: '
    assert_file_contains "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" 'global_bar'

    temp_del "${HELM_SECRETS_DEC_DIR}"
}

@test "dec: Decrypt secrets.yaml + http://" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
}

@test "dec: Decrypt secrets.yaml + http://example.com/404.yaml" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="http://example.com/404.yaml"

    run helm secrets dec "${FILE}"
    assert_failure
    assert_output --partial "[helm-secrets] File does not exist: ${FILE}"
}

@test "dec: Decrypt secrets.yaml + git://" {
    if ! is_driver "sops" || on_windows; then
        skip
    fi

    FILE="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"

    run helm secrets dec "${FILE}"
    assert_success
    assert_output "[helm-secrets] Decrypting ${FILE}"
}

@test "dec: secrets.yaml + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets --driver-args "--verbose" dec "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: secrets.yaml + -a (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets -a "--verbose" dec "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: secrets.yaml + HELM_SECRETS_DRIVER_ARGS (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DRIVER_ARGS=--verbose
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets dec "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: secrets.yaml + --driver-args (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets --driver-args "--verbose --output-type \"yaml\"" dec "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}

@test "dec: secrets.yaml + -a (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets -a "--verbose --output-type \"yaml\"" dec "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec"  'global_secret: '
    assert_file_contains "${FILE}.dec"  'global_bar'
}

@test "dec: secrets.yaml + HELM_SECRETS_DRIVER_ARGS (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    # shellcheck disable=SC2089
    HELM_SECRETS_DRIVER_ARGS="--verbose --output-type \"yaml\""
    # shellcheck disable=SC2090
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets dec "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'global_secret: '
    assert_file_contains "${FILE}.dec" 'global_bar'
}
