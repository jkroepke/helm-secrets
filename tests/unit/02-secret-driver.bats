#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "secret-driver: helm secrets -d" {
     run helm secrets -d nonexists view "tests/assets/helm_vars/secrets.yaml"
     assert_failure
     assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets --driver" {
     run helm secrets --driver nonexists view "tests/assets/helm_vars/secrets.yaml"
     assert_failure
     assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets w/ env SECRET_DRIVER" {
     SECRET_DRIVER=nonexists
     export SECRET_DRIVER

     run helm secrets view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_failure
     assert_output --partial "Can't find secret driver: nonexists"
}

@test "secret-driver: helm secrets -d sops" {
     run helm secrets -d sops view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_success
     assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets --driver sops" {
     run helm secrets --driver sops view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_success
     assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets w/ env SECRET_DRIVER=sops" {
     SECRET_DRIVER=sops
     export SECRET_DRIVER

     run helm secrets view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_success
     assert_output --partial 'global_secret: global_bar'
}

@test "secret-driver: helm secrets -d noop" {
     run helm secrets -d noop view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_success
     assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets --driver noop" {
     run helm secrets --driver noop view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_success
     assert_output --partial 'sops:'
}

@test "secret-driver: helm secrets w/ env SECRET_DRIVER=noop" {
     SECRET_DRIVER=noop
     export SECRET_DRIVER=noop

     run helm secrets view "${TEST_DIR}/assets/helm_vars/secrets.yaml"
     assert_success
     assert_output --partial 'sops:'
}
