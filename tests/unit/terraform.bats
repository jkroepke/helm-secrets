#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "terraform: read valid file" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    run helm secrets terraform "${FILE}"
    assert_success
    assert_output --regexp '^{"content_base64":".+"}$'
}

@test "terraform: read invalid file" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/non-exists.yaml"

    run helm secrets terraform "${FILE}"
    assert_failure
    assert_output --partial '[helm-secrets] File does not exist:'
}
