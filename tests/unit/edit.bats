#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "edit: helm edit" {
    run "${HELM_BIN}" secrets edit
    assert_failure
    assert_output --partial 'Edit encrypted secrets'
}

@test "edit: helm edit --help" {
    run "${HELM_BIN}" secrets edit --help
    assert_success
    assert_output --partial 'Edit encrypted secrets'
}

@test "edit: File if not exits + no valid encryption config" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    run "${HELM_BIN}" secrets edit nonexists
    assert_failure
    assert_output --partial 'config file not found and no keys provided through command line options'
}

@test "edit: File if not exits + valid encryption config" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_ROOT}/assets/mock-editor/editor.sh"

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/nonexists.yaml"

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets decrypt "${FILE}"
    assert_success
    assert_output "hello: world"
}

@test "edit: secrets.yaml" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_ROOT}/assets/mock-editor/editor.sh"

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets decrypt "${FILE}"
    assert_success
    assert_output "hello: world"
}

@test "edit: some-secrets.yaml" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_ROOT}/assets/mock-editor/editor.sh"

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets decrypt "${FILE}"
    assert_success
    assert_output "hello: world"
}

@test "edit: secrets.yaml + special path" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_ROOT}/assets/mock-editor/editor.sh"

    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run env EDITOR="${EDITOR}" "${HELM_BIN}" secrets decrypt "${FILE}"
    assert_success
    assert_output "hello: world"
}
