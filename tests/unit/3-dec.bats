#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "dec: helm dec" {
  run helm secrets dec
  assert_failure
  assert_output --partial 'Error: secrets file required.'
}

@test "dec: helm dec --help" {
  run helm secrets dec --help
  assert_success
  assert_output --partial 'Decrypt secrets'
}

@test "dec: File not exits" {
  run helm secrets dec nonexists
  assert_failure
  assert_output --partial 'File does not exist: nonexists'
}

@test "dec: Decrypt assets/helm_vars/secrets.yaml" {
  FILE=tests/assets/helm_vars/secrets.yaml

  run helm secrets dec "${FILE}"
  assert_success
  assert_output "Decrypting ${FILE}"
  assert [ -e "${FILE}.dec" ]

  run cat "${FILE}.dec"
  assert_success
  assert_output 'global_secret: global_bar'
}

@test "dec: Decrypt assets/helm_vars/secrets.yaml with HELM_SECRETS_DEC_SUFFIX" {
  HELM_SECRETS_DEC_SUFFIX=.yaml.test
  export HELM_SECRETS_DEC_SUFFIX

  FILE=tests/assets/helm_vars/secrets.yaml

  run helm secrets dec "${FILE}"
  assert_success
  assert_output "Decrypting ${FILE}"
  assert [ -e "${FILE}.test" ]

  run cat "${FILE}.test"
  assert_success
  assert_output 'global_secret: global_bar'
}

@test "dec: Decrypt assets/helm_vars/secrets.yaml with HELM_SECRETS_DEC_DIR" {
  HELM_SECRETS_DEC_DIR="$(mktemp -d)"
  export HELM_SECRETS_DEC_DIR

  FILE=tests/assets/helm_vars/secrets.yaml

  run helm secrets dec "${FILE}"
  assert_success
  assert_output "Decrypting ${FILE}"
  assert [ -e "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec" ]

  run cat "${HELM_SECRETS_DEC_DIR}/secrets.yaml.dec"
  assert_success
  assert_output 'global_secret: global_bar'
}
