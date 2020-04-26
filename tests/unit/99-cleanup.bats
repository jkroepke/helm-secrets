#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "Cleanup test environment" {
  # Reset test environment
  run git checkout HEAD -- tests/assets/helm_vars/
  assert_success
}
