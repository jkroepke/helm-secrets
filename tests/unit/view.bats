#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "view: helm view" {
    run helm secrets view
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "view: helm view --help" {
    run helm secrets view --help
    assert_success
    assert_output --partial 'View specified encrypted yaml file'
}

@test "view: File not exits" {
    run helm secrets view nonexists
    assert_failure
    assert_output --partial 'File does not exist: nonexists'
}

@test "view: secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: values.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/values.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_values'
}

@test "view: secrets.yaml + special char directory name" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets --driver-args "--verbose" view "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + -a (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets -a "--verbose" view "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + HELM_SECRETS_DRIVER_ARGS (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    HELM_SECRETS_DRIVER_ARGS=--verbose
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + --driver-args (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets --driver-args "--verbose --output-type \"yaml\"" view "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + -a (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets -a "--verbose --output-type \"yaml\"" view "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + HELM_SECRETS_DRIVER_ARGS (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    # shellcheck disable=SC2089
    HELM_SECRETS_DRIVER_ARGS="--verbose --output-type \"yaml\""
    # shellcheck disable=SC2090
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}
