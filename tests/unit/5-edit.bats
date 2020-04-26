#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "clean: helm edit" {
  run helm secrets clean
  assert_failure
  assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: helm edit --help" {
  run helm secrets clean --help
  assert_success
  assert_output --partial 'Clean all decrypted files if any exist'
}

@test "clean: Directory not exits" {
  run helm secrets edit nonexists
  assert_failure
  assert_output --partial 'File does not exist: nonexists'
}

@test "edit: Edit tests/assets/helm_vars/projectY/production/us-east-1/java-app/" {
  EDITOR=tests/assets/mock-editor/editor.sh
  export EDITOR

  FILE=tests/assets/helm_vars/projectY/production/us-east-1/java-app/secrets.yaml

  run helm secrets edit "${FILE}"
  assert_success

  run helm secrets view "${FILE}"
  assert_success
  assert_output "hello: world"
}
