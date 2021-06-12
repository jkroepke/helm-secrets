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

@test "helm-plugin: helm secrets -v" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run helm secrets -v
    assert_success
    assert_output "${VERSION}"
}

@test "helm-plugin: helm secrets --version" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run helm secrets --version
    assert_success
    assert_output "${VERSION}"
}

@test "helm-plugin: helm secrets version" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run helm secrets version
    assert_success
    assert_output "${VERSION}"
}
