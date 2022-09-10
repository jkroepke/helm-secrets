#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "decrypt: helm decrypt" {
    run "${HELM_BIN}" secrets decrypt
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "decrypt: helm decrypt --help" {
    run "${HELM_BIN}" secrets decrypt --help
    assert_output --partial 'Decrypt secrets'
    assert_success
}

@test "decrypt: File not exits" {
    run "${HELM_BIN}" secrets decrypt nonexists
    assert_failure
    assert_output --partial '[helm-secrets] File does not exist: nonexists'
}

@test "decrypt: Decrypt secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt inline secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt -i "${VALUES_PATH}"
    assert_success

    assert_file_contains "${VALUES_PATH}" 'global_secret: global_bar'
}

@test "decrypt: Decrypt secrets.yaml.gotpl" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml.gotpl"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_tpl'
    assert_success
}

@test "decrypt: Decrypt some-secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt values.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/values.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] File is not encrypted: .*${VALUES}"
    assert_failure
}

@test "decrypt: Decrypt secrets.yaml + special char directory name" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + http://" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run "${HELM_BIN}" secrets decrypt "${VALUES}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + http://example.com/404.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="http://example.com/404.yaml"

    run "${HELM_BIN}" secrets decrypt "${VALUES}"
    assert_failure
    assert_output --partial "[helm-secrets] File does not exist: ${VALUES}"
}

@test "decrypt: Decrypt secrets.yaml + git://" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"

    run "${HELM_BIN}" secrets decrypt "${VALUES}"
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + --backend-args (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --backend-args "--verbose" decrypt "${VALUES_PATH}"
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + -a (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets -a "--verbose" decrypt "${VALUES_PATH}"
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + HELM_SECRETS_BACKEND_ARGS (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_BACKEND_ARGS=--verbose

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + --backend-args (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --backend-args "--verbose --output-type \"yaml\"" decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + -a (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets -a "--verbose --output-type \"yaml\"" decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + HELM_SECRETS_BACKEND_ARGS (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_BACKEND_ARGS="--verbose --output-type \"yaml\""

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml in terraform mode" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run "${HELM_BIN}" secrets decrypt --terraform "${FILE}"

    # assert that there are no new lines in the base64
    assert_output --regexp '\{"content_base64":"([A-Za-z0-9=]*)"\}'

    assert_success
}
