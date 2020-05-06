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
    assert_output --partial 'View specified secrets[.*].yaml file'
}

@test "view: File not exits" {
    run helm secrets view nonexists
    assert_failure
    assert_output --partial 'File does not exist: nonexists'
}

@test "view: secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "view: secrets.yaml + special char directory name" {
    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}
