#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "Prepare test environment" {
    tests_setup

    run mkdir -p "${TEST_HOME}/.kube"
    assert_success

    run cp "${HOME}/.kube/config" "${TEST_HOME}/.kube/config"
    assert_success
}
