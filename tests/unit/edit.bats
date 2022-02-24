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
    if ! is_driver "sops" || on_windows; then
        skip
    fi

    run "${HELM_BIN}" secrets edit nonexists
    assert_failure
    assert_output --partial 'config file not found and no keys provided through command line options'
}

@test "edit: File if not exits + valid encryption config" {
    if ! is_driver "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_DIR}/assets/mock-editor/editor.sh"
    export EDITOR

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/nonexists.yaml"

    run "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output "hello: world"
}

@test "edit: secrets.yaml" {
    if ! is_driver "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_DIR}/assets/mock-editor/editor.sh"
    export EDITOR

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output "hello: world"
}

@test "edit: some-secrets.yaml" {
    if ! is_driver "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_DIR}/assets/mock-editor/editor.sh"
    export EDITOR

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    run "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output "hello: world"
}


@test "edit: secrets.yaml + special path" {
    if ! is_driver "sops" || on_windows; then
        skip
    fi

    EDITOR="${TEST_DIR}/assets/mock-editor/editor.sh"
    export EDITOR

    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run "${HELM_BIN}" secrets edit "${FILE}"
    assert_success

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output "hello: world"
}
