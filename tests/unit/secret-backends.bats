#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "secret-backend: helm secrets -b" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -b nonexists decrypt "${FILE}"

    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets --backend" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend nonexists decrypt "${FILE}"

    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets --backend=" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend=nonexists decrypt "${FILE}"

    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets --backend=nonexists + HELM_SECRETS_ALLOWED_BACKENDS=noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_ALLOWED_BACKENDS=noop WSLENV="HELM_SECRETS_ALLOWED_BACKENDS:${WSLENV}" \
        "${HELM_BIN}" secrets --backend=nonexists decrypt "${FILE}"

    assert_output --partial "secret backend '${HELM_SECRETS_BACKEND}' not allowed"
    assert_failure
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=nonexists WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" \
        "${HELM_BIN}" secrets decrypt "${FILE}"

    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "secret-backend: helm secrets -b noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -b noop decrypt "${FILE}"

    assert_output -e "unencrypted_suffix:"
    assert_success
}

@test "secret-backend: helm secrets --backend noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets --backend noop decrypt "${FILE}"

    assert_output -e "unencrypted_suffix:"
    assert_success
}

@test "secret-backend: helm secrets -b noop + q flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run "${HELM_BIN}" secrets -q -b noop decrypt "${FILE}"

    assert_output -e "unencrypted_suffix:"
    assert_success
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=noop" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=noop WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets decrypt "${FILE}"

    assert_output -e "unencrypted_suffix:"
    assert_success
}

@test "secret-backend: helm secrets + prefer cli arg -b noop over env" {
    FILE="${TEST_TEMP_DIR}/assets/values/sops/secrets.yaml"

    run env HELM_SECRETS_BACKEND=sops WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets -b noop decrypt "${FILE}"

    assert_output -e "unencrypted_suffix:"
    assert_success
}

@test "secret-backend: helm secrets --backend assets/custom-backend.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/custom-backend/secrets.yaml"

    run "${HELM_BIN}" secrets --backend "${TEST_TEMP_DIR}/assets/custom-backend.sh" decrypt "${FILE}"

    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
    assert_success
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=assets/custom-backend.sh" {
    FILE="${TEST_TEMP_DIR}/assets/values/custom-backend/secrets.yaml"

    run env HELM_SECRETS_BACKEND="${TEST_TEMP_DIR}/assets/custom-backend.sh" WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets decrypt "${FILE}"

    refute_output --partial '!vault'
    assert_output --partial 'production#global_secret'
    assert_success
}

@test "secret-backend: helm secrets --backend ${GIT_ROOT}/examples/backends/onepassword.sh" {
    if ! is_custom_backend "onepassword"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/custom-backend/onepassword-secrets.yaml"

    run "${HELM_BIN}" secrets --backend "${GIT_ROOT}/examples/backends/onepassword.sh" decrypt "${FILE}"

    refute_output --partial 'op://'
    assert_output --partial 'test-username'
    assert_output --partial 'mytestpassword123'
    assert_output --partial 'a-test-name'
    assert_output --partial 'my-test@example.com'
    assert_success
}

@test "secret-backend: helm secrets + env HELM_SECRETS_BACKEND=${GIT_ROOT}/examples/backends/onepassword.sh" {
    if ! is_custom_backend "onepassword"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/custom-backend/onepassword-secrets.yaml"

    run env HELM_SECRETS_BACKEND="${GIT_ROOT}/examples/backends/onepassword.sh" WSLENV="HELM_SECRETS_BACKEND:${WSLENV}" "${HELM_BIN}" secrets decrypt "${FILE}"

    refute_output --partial 'op://'
    assert_output --partial 'test-username'
    assert_output --partial 'mytestpassword123'
    assert_output --partial 'a-test-name'
    assert_output --partial 'my-test@example.com'
    assert_success
}
