#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "view: helm view" {
  run helm secrets view
  assert_failure
  assert_output --partial 'Error: secrets file required.'
}

@test "view: helm view --help" {
  run helm secrets view --help
  assert_success
  assert_output --partial 'View specified secrets[.*].yaml file'
}

@test "view: File not exits" {
  run helm secrets view nonexists
  assert_failure
  assert_output --partial 'File does not exist: nonexists'
}

@test "view: View assets/helm_vars/secrets.yaml" {
  FILE=tests/assets/helm_vars/secrets.yaml

  run helm secrets view "${FILE}"
  assert_success
  assert_output 'global_secret: global_bar'
}
