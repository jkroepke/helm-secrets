#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "enc: helm enc" {
    run helm secrets enc
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "enc: helm enc --help" {
    run helm secrets enc --help
    assert_success
    assert_output --partial 'Encrypt secrets'
}

@test "enc: File not exits" {
    run helm secrets enc nonexists
    assert_failure
    assert_output --partial 'File does not exist: nonexists'
}

@test "enc: Encrypt secrets.yaml" {
    if [ "${HELM_SECRETS_DRIVER}" != "sops" ]; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt some-secrets.yaml" {
    if [ "${HELM_SECRETS_DRIVER}" != "sops" ]; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/some-secrets.dec.yaml"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted some-secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml.dec" {
    if [ "${HELM_SECRETS_DRIVER}" != "sops" ]; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    cp "${FILE}" "${FILE}.dec"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted ./secrets.dec.yaml.dec to secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml + special char directory name" {
    if [ "${HELM_SECRETS_DRIVER}" != "sops" ]; then
        skip
    fi

    if is_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_SUFFIX" {
    if [ "${HELM_SECRETS_DRIVER}" != "sops" ]; then
        skip
    fi
    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    cp "${FILE}" "${FILE}.test"

    HELM_SECRETS_DEC_SUFFIX=.yaml.test
    export HELM_SECRETS_DEC_SUFFIX

    run helm secrets enc "${FILE}"
    assert_success
    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted ./secrets.dec.yaml.test to secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.tmp.yaml" {
    if [ "${HELM_SECRETS_DRIVER}" != "sops" ]; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/values/${HELM_SECRETS_DRIVER}/secrets.tmp.yaml"

    YAML="hello: world"
    echo "${YAML}" > "${FILE}"

    run helm secrets enc "${FILE}"
    assert_success
    assert_output --partial "Encrypting ${FILE}"

    run helm secrets dec "${FILE}"
    assert_success

    run cat "${FILE}.dec"
    assert_success
    assert_output 'hello: world'
}
