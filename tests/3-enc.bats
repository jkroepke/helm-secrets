#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "enc: File not exits" {
  run helm secrets enc nonexists
  assert_failure
  assert_output --partial 'File does not exist: nonexists'
}
