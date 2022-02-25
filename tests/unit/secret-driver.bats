#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "secret-driver: helm secrets -d" {
    FILE="${TEST_TEMP_DIR}/assets/values/noop/secrets.yaml"

    run "${HELM_BIN}" secrets -d nonexists view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets --driver" {
    FILE="${TEST_TEMP_DIR}/assets/values/noop/secrets.yaml"

    run "${HELM_BIN}" secrets --driver nonexists view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER" {
    HELM_SECRETS_DRIVER=nonexists
    export HELM_SECRETS_DRIVER
    export WSLENV="HELM_SECRETS_DRIVER:${WSLENV}"

    FILE="${TEST_TEMP_DIR}/assets/values/noop/secrets.yaml"

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets -d sops" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -d sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets --driver sops" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --driver sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets -d sops + q flag" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -q -d sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=sops" {
    if ! is_driver "sops"; then
        skip
    fi

    HELM_SECRETS_DRIVER=sops
    export HELM_SECRETS_DRIVER
    export WSLENV="HELM_SECRETS_DRIVER:${WSLENV}"

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets -d noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -d noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets --driver noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --driver noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=noop" {
    HELM_SECRETS_DRIVER=noop
    export HELM_SECRETS_DRIVER
    export WSLENV="HELM_SECRETS_DRIVER:${WSLENV}"

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets + prefer cli arg -d noop over env" {
    HELM_SECRETS_DRIVER=sops
    export HELM_SECRETS_DRIVER
    export WSLENV="HELM_SECRETS_DRIVER:${WSLENV}"

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -d noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets --driver envsubst" {
    if command -v envsubst > /dev/null 2>&1; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/envsubst/secrets.yaml"

    run "${HELM_BIN}" secrets --driver "envsubst" view "${FILE}"
    assert_success
    refute_output --partial "\${global_bar}"
    assert_output --partial 'key: "-----BEGIN PGP MESSAGE-----'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=envsubst" {
    if command -v envsubst > /dev/null 2>&1; then
        skip
    fi

    HELM_SECRETS_DRIVER="envsubst"
    export HELM_SECRETS_DRIVER
    export WSLENV="HELM_SECRETS_DRIVER:${WSLENV}"

    FILE="${TEST_TEMP_DIR}/assets/values/envsubst/secrets.yaml"

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    refute_output --partial "\${global_bar}"
    assert_output --partial 'key: "-----BEGIN PGP MESSAGE-----'
}

@test "secret-driver: helm secrets --driver assets/custom-driver.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/vault/secrets.yaml"

    run "${HELM_BIN}" secrets --driver "${TEST_TEMP_DIR}/assets/custom-driver.sh" view "${FILE}"
    assert_success
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
}

@test "secret-driver: helm secrets + env HELM_SECRETS_DRIVER=assets/custom-driver.sh" {
    HELM_SECRETS_DRIVER="${TEST_TEMP_DIR}/assets/custom-driver.sh"
    export HELM_SECRETS_DRIVER
    export WSLENV="HELM_SECRETS_DRIVER:${WSLENV}"

    FILE="${TEST_TEMP_DIR}/assets/values/vault/secrets.yaml"

    run "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
}
