#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

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

@test "enc: Encrypt assets/helm_vars/secrets.yaml" {
  FILE=tests/assets/helm_vars/secrets.yaml

  run helm secrets enc "${FILE}"
  assert_success
  assert_output --partial "Encrypting ${FILE}"
  assert_output --partial "Encrypted ./secrets.yaml.dec to secrets.yaml"

  run helm secrets view "${FILE}"
  assert_success
  assert_output 'global_secret: global_bar'
}

@test "enc: Encrypt assets/helm_vars/secrets.yaml with HELM_SECRETS_DEC_SUFFIX" {
  HELM_SECRETS_DEC_SUFFIX=.yaml.test
  export HELM_SECRETS_DEC_SUFFIX

  FILE=tests/assets/helm_vars/secrets.yaml

  run helm secrets enc "${FILE}"
  assert_success
  assert_output --partial "Encrypting ${FILE}"
  assert_output --partial "Encrypted ./secrets.yaml.test to secrets.yaml"

  run helm secrets view "${FILE}"
  assert_success
  assert_output 'global_secret: global_bar'
}

@test "enc: Encrypt assets/helm_vars/secrets.tmp.yaml" {
  FILE=tests/assets/helm_vars/secrets.tmp.yaml

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
