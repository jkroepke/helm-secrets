#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "secret-backend: helm secrets -b" {
    FILE="${TEST_TEMP_DIR}/assets/values/noop/secrets.yaml"

    run "${HELM_BIN}" secrets -b nonexists view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret backend: nonexists"
}

@test "secret-backend: helm secrets --backend" {
    FILE="${TEST_TEMP_DIR}/assets/values/noop/secrets.yaml"

    run "${HELM_BIN}" secrets --backend nonexists view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret backend: nonexists"
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND" {
    FILE="${TEST_TEMP_DIR}/assets/values/noop/secrets.yaml"

    run env HELM_SECRETS_BACKEND=nonexists WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_failure
    assert_output --partial "Can't find secret backend: nonexists"
}

@test "secret-backend: helm secrets -b sops" {
    if ! is_backend "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -b sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-backend: helm secrets --backend sops" {
    if ! is_backend "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-backend: helm secrets -b sops + q flag" {
    if ! is_backend "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -q -b sops view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=sops" {
    if ! is_backend "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=sops WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: global_bar'
}

@test "secret-backend: helm secrets -b noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -b noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-backend: helm secrets --backend noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=noop WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-backend: helm secrets + prefer cli arg -b noop over env" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=sops WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets -b noop view "${FILE}"
    assert_success
    assert_output --partial 'sops:'
}

@test "secret-backend: helm secrets --backend envsubst" {
    if ! command -v envsubst >/dev/null 2>&1; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/envsubst/secrets.yaml"

    run "${HELM_BIN}" secrets --backend "envsubst" view "${FILE}"
    assert_success
    refute_output --partial "\${global_bar}"
    assert_output --partial 'key: "-----BEGIN PGP MESSAGE-----'
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=envsubst" {
    if ! command -v envsubst >/dev/null 2>&1; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/envsubst/secrets.yaml"

    run env HELM_SECRETS_BACKEND="envsubst" WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    refute_output --partial "\${global_bar}"
    assert_output --partial 'key: "-----BEGIN PGP MESSAGE-----'
}

@test "secret-backend: helm secrets --backend assets/custom-backend.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/vault/secrets.yaml"

    run "${HELM_BIN}" secrets --backend "${TEST_TEMP_DIR}/assets/custom-backend.sh" view "${FILE}"
    assert_success
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=assets/custom-backend.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/vault/secrets.yaml"

    run env HELM_SECRETS_BACKEND="${TEST_TEMP_DIR}/assets/custom-backend.sh" WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets view "${FILE}"
    assert_success
    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
}
