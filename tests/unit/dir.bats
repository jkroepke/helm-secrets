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

    run helm secrets dir
    assert_success
    assert_output "$(helm env HELM_PLUGINS)${DS}helm-secrets"
}
