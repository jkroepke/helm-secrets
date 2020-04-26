#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "install: helm plugin install" {
  run helm plugin install "$(git rev-parse --show-toplevel)"
  assert_success
  assert [ -e "${TEST_HOME}/.gitconfig" ]
}

@test "install: helm plugin list" {
  run helm plugin list
  assert_success
  assert_output --partial 'secrets'
}

@test "install: helm secrets" {
  run helm secrets
  assert_failure
  assert_output --partial 'Available Commands:'
}

@test "install: helm secrets --help" {
  run helm secrets --help
  assert_success
  assert_output --partial 'Available Commands:'
}
