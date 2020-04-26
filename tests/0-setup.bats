#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "Prepare test environment" {
  # Reset test environment
  run git checkout HEAD -- tests/assets/helm_vars/
  assert_success

  run rm -rf "${TEST_HOME}" "${GIT_ROOT}/tests/tmp/"
  assert_success

  run mkdir -p "${TEST_HOME}" "${GIT_ROOT}/tests/tmp/"
  assert_success

  run find tests/assets \( -name '*.yaml.*' -o -name 'secrets.tmp.yaml' \) -delete
  assert_success

  run gpg --batch --import "${GIT_ROOT}/tests/assets/pgp/projectx.asc"
  assert_success

  run gpg --batch --import "${GIT_ROOT}/tests/assets/pgp/projecty.asc"
  assert_success
}
