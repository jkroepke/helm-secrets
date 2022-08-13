#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "secret-backend: helm secrets -b" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -b nonexists view "${FILE}"
    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets --backend" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend nonexists view "${FILE}"
    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=nonexists WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets -b noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -b noop view "${FILE}"
    assert_output --partial 'sops:'
    assert_success
}

@test "secret-backend: helm secrets --backend noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend noop view "${FILE}"
    assert_output --partial 'sops:'
    assert_success
}

@test "secret-backend: helm secrets -b noop + q flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -q -b noop view "${FILE}"
    assert_output --partial 'sops:'
    assert_success
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=noop WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_output --partial 'sops:'
    assert_success
}

@test "secret-backend: helm secrets + prefer cli arg -b noop over env" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=sops WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets -b noop view "${FILE}"
    assert_output --partial 'sops:'
    assert_success
}

@test "secret-backend: helm secrets --backend assets/custom-backend.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/custom-backend/secrets.yaml"

    run "${HELM_BIN}" secrets --backend "${TEST_TEMP_DIR}/assets/custom-backend.sh" view "${FILE}"
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
    assert_success
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=assets/custom-backend.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/custom-backend/secrets.yaml"

    run env HELM_SECRETS_BACKEND="${TEST_TEMP_DIR}/assets/custom-backend.sh" WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
    assert_success
}
