#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "helm-plugin: helm plugin list" {
    run helm plugin list
    assert_success
    assert_output --partial 'secrets'
}

@test "helm-plugin: helm secrets" {
    run helm secrets
    assert_failure
    assert_output --partial 'Available Commands:'
}

@test "helm-plugin: helm secrets --help" {
    run helm secrets --help
    assert_success
    assert_output --partial 'Available Commands:'
}
