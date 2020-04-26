#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "clean: helm clean" {
  run helm secrets clean
  assert_failure
  assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: helm clean --help" {
  run helm secrets clean --help
  assert_success
  assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: Directory not exits" {
  run helm secrets clean nonexists
  assert_failure
  assert_output --partial 'Directory does not exist: nonexists'
}

@test "clean: Cleanup" {
  FILE=tests/assets/helm_vars/projectX/production/us-east-1/java-app/secrets.yaml

  run helm secrets dec "${FILE}"
  assert_success
  assert [ -f "${FILE}.dec" ]

  run helm secrets clean "$(dirname "${FILE}")"
  assert [ ! -f "${FILE}.dec" ]
  assert_output --partial "${FILE}.dec"
}


@test "clean: Cleanup with HELM_SECRETS_DEC_SUFFIX" {
  HELM_SECRETS_DEC_SUFFIX=.yaml.test
  export HELM_SECRETS_DEC_SUFFIX

  FILE=tests/assets/helm_vars/projectX/production/us-east-1/java-app/secrets.yaml

  run helm secrets dec "${FILE}"
  assert_success
  assert [ -f "${FILE}.test" ]

  run helm secrets clean "$(dirname "${FILE}")"
  assert [ ! -f "${FILE}.test" ]
  assert_output --partial "${FILE}.test"
}
