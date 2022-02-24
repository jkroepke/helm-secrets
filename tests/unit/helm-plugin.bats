#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "helm-plugin: helm plugin list" {
    run "${HELM_BIN}"plugin list
    assert_success
    assert_output --partial 'secrets'
}

@test "helm-plugin: helm secrets" {
    run "${HELM_BIN}" secrets
    assert_failure
    assert_output --partial 'Available Commands:'
}

@test "helm-plugin: helm secrets --help" {
    run "${HELM_BIN}" secrets --help
    assert_success
    assert_output --partial 'Available Commands:'
}

@test "helm-plugin: helm secrets -v" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run "${HELM_BIN}" secrets -v
    assert_success
    assert_output "${VERSION}"
}

@test "helm-plugin: helm secrets --version" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run "${HELM_BIN}" secrets --version
    assert_success
    assert_output "${VERSION}"
}

@test "helm-plugin: helm secrets version" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run "${HELM_BIN}" secrets version
    assert_success
    assert_output "${VERSION}"
}
