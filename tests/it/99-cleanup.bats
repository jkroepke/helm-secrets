#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "Cleanup test environment" {
    tests_cleanup
}
