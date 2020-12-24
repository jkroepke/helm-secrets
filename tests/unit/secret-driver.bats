#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "secret-driver: helm secrets -d" {
    FILE="${TEST_TEMP_DIR}/values/noop/secrets.yaml"

    run helm secrets -d nonexists view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets --driver" {
    FILE="${TEST_TEMP_DIR}/values/noop/secrets.yaml"

    run helm secrets --driver nonexists view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER" {
    # shellcheck disable=SC2030
    HELM_SECRETS_DRIVER=nonexists
    export HELM_SECRETS_DRIVER

    FILE="${TEST_TEMP_DIR}/values/noop/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets -d sops" {
    # shellcheck disable=SC2031
    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets -d sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets --driver sops" {
    # shellcheck disable=SC2031
    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets --driver sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets -d sops + q flag" {
    # shellcheck disable=SC2031
    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets -q -d sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=sops" {
    HELM_SECRETS_DRIVER=sops
    export HELM_SECRETS_DRIVER

    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets -d noop" {
    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets -d noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets --driver noop" {
    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets --driver noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=noop" {
    HELM_SECRETS_DRIVER=noop
    export HELM_SECRETS_DRIVER=noop

    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}


@test "secret-driver: helm secrets + prefer cli arg -d noop over env" {
    HELM_SECRETS_DRIVER=sops
    export HELM_SECRETS_DRIVER=sops

    FILE="${TEST_TEMP_DIR}/values/sops/secrets.yaml"

    run helm secrets -d noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets --driver assets/custom-driver.sh" {
    FILE="${TEST_TEMP_DIR}/values/vault/secrets.yaml"

    run helm secrets --driver "${TEST_TEMP_DIR}/custom-driver.sh" view "${FILE}"
    assert_success
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=assets/custom-driver.sh" {
    HELM_SECRETS_DRIVER="${TEST_TEMP_DIR}/assets/custom-driver.sh"
    export HELM_SECRETS_DRIVER="${TEST_TEMP_DIR}/custom-driver.sh"

    FILE="${TEST_TEMP_DIR}/values/vault/secrets.yaml"

    run helm secrets view "${FILE}"
    assert_success
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
}
