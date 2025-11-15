#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "helm-plugin: helm plugin list" {
    run "${HELM_BIN}" plugin list
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
    assert_output --partial "${VERSION}"
}

@test "helm-plugin: helm secrets --version" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run "${HELM_BIN}" secrets --version
    assert_success
    assert_output --partial "${VERSION}"
}

@test "helm-plugin: helm secrets version + HELM_SECRETS_WRAPPER_ENABLED" {
    VERSION=$(grep version "${GIT_ROOT}/plugin.yaml" | cut -d'"' -f2) >&2

    run env HELM_SECRETS_WRAPPER_ENABLED=true "${GIT_ROOT}/scripts/wrapper/helm.sh" version
    assert_success

    if helm_version_greater_or_equal_than 4.0.0; then
        assert_output --partial "v4"
    else
        assert_output --partial "v3"
    fi
}
