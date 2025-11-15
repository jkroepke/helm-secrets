#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "dir: helm dir" {
    if on_windows; then
        DS="\\"
    else
        DS="/"
    fi

    run "${HELM_BIN}" secrets dir
    assert_success

    if helm_version_greater_or_equal_than 4.0.0; then
        assert_output --partial "$("${HELM_BIN}" env HELM_PLUGINS)${DS}helm-secrets-cli"
    else
        assert_output --partial "$("${HELM_BIN}" env HELM_PLUGINS)${DS}helm-secrets"
    fi
}
