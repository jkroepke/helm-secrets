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
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt some-secrets.yaml" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.dec.yaml"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted some-secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml.dec" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    cp "${FILE}" "${FILE}.dec"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted secrets.dec.yaml.dec to secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml + special char directory name" {
    if ! is_driver "sops"; then
        skip
    fi

    if on_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    run helm secrets enc "${FILE}"

    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_PREFIX" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    DIR="$(dirname "${FILE}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    export HELM_SECRETS_DEC_PREFIX
    HELM_SECRETS_DEC_SUFFIX=""
    export HELM_SECRETS_DEC_SUFFIX

    echo "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml" >&2
    cp "${FILE}" "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml"

    run helm secrets enc "${FILE}"
    assert_success
    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted ${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml to secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_SUFFIX" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"

    HELM_SECRETS_DEC_SUFFIX=.test
    export HELM_SECRETS_DEC_SUFFIX
    cp "${FILE}" "${FILE}${HELM_SECRETS_DEC_SUFFIX}"

    run helm secrets enc "${FILE}"
    assert_success
    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX} to secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.yaml with HELM_SECRETS_DEC_PREFIX + HELM_SECRETS_DEC_SUFFIX" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.dec.yaml"
    DIR="$(dirname "${FILE}")"

    HELM_SECRETS_DEC_PREFIX=prefix.
    export HELM_SECRETS_DEC_PREFIX
    HELM_SECRETS_DEC_SUFFIX=.foo
    export HELM_SECRETS_DEC_SUFFIX
    cp "${FILE}" "${DIR}/${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX}"

    run helm secrets enc "${FILE}"
    assert_success
    assert_output --partial "Encrypting ${FILE}"
    assert_output --partial "Encrypted ${HELM_SECRETS_DEC_PREFIX}secrets.dec.yaml${HELM_SECRETS_DEC_SUFFIX} to secrets.dec.yaml"

    run helm secrets view "${FILE}"
    assert_success
    assert_output --partial 'global_secret: '
    assert_output --partial 'global_bar'
}

@test "enc: Encrypt secrets.tmp.yaml" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.tmp.yaml"

    YAML="hello: world"
    echo "${YAML}" > "${FILE}"

    run helm secrets enc "${FILE}"
    assert_success
    assert_output --partial "Encrypting ${FILE}"

    run helm secrets dec "${FILE}"
    assert_success
    assert_file_exist "${FILE}.dec"
    assert_file_contains "${FILE}.dec" 'hello: world'
}
