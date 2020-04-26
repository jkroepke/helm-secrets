#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "Setup" {
  run rm -rf "${TEST_HOME}"
  assert_success

  run mkdir -p "${TEST_HOME}"
  assert_success

  run find tests/assets -name '*.yaml.*' -delete
  assert_success

  run gpg --batch --import tests/assets/pgp/projectx.asc
  assert_success

  run gpg --batch --import tests/assets/pgp/projecty.asc
  assert_success
}
