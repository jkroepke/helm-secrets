#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "plugin-install: helm plugin install" {
    HOME=$(mktemp -d)
    run helm plugin install "${GIT_ROOT}"
    assert_output --regexp "$(printf "sops is already installed: sops .*\nInstalled plugin: secrets")"
    assert_file_exist "${HOME}/.gitconfig"
}

@test "plugin-install: SKIP_SOPS_INSTALL=true helm plugin install" {
    SKIP_SOPS_INSTALL=true
    export SKIP_SOPS_INSTALL

    HOME=$(mktemp -d)

    run helm plugin install "${GIT_ROOT}"
    assert_output --regexp "$(printf "Skipping sops installation.\nInstalled plugin: secrets")"
    assert_file_exist "${HOME}/.gitconfig"
}

@test "plugin-install: helm plugin list" {
    run helm plugin list
    assert_success
    assert_output --partial 'secrets'
}

@test "plugin-install: helm secrets" {
    run helm secrets
    assert_failure
    assert_output --partial 'Available Commands:'
}

@test "plugin-install: helm secrets --help" {
    run helm secrets --help
    assert_success
    assert_output --partial 'Available Commands:'
}
