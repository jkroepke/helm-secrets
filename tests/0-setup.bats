#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "Prepare test environment" {
  # Reset test environment
  run git checkout HEAD -- "${TEST_DIR}/assets/helm_vars/"
  assert_success

  run rm -rf "${TEST_HOME}" "${TEST_DIR}/tmp/"
  assert_success

  run mkdir -p "${TEST_HOME}" "${TEST_DIR}/tmp/"
  assert_success

  run find "${TEST_DIR}/assets" \( -name '*.yaml.*' -o -name 'secrets.tmp.yaml' \) -delete
  assert_success

  run gpg --batch --import "${TEST_DIR}/assets/pgp/projectx.asc"
  assert_success

  run gpg --batch --import "${TEST_DIR}/assets/pgp/projecty.asc"
  assert_success
}
