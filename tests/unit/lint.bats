#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "lint: helm lint" {
    run "${HELM_BIN}" secrets lint

    assert_output --partial 'helm secrets [ OPTIONS ] lint'
    assert_success
}

@test "lint: helm lint --help" {
    run "${HELM_BIN}" secrets lint --help

    assert_output --partial 'helm secrets [ OPTIONS ] lint'
    assert_success
}

@test "lint: helm lint w/ chart" {
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial '1 chart(s) linted, 0 chart(s) failed'
    assert_success
}

@test "lint: helm lint w/ chart + secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + --values" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" --values "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + --values=" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" --values="${VALUES_PATH}" 2>&1
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml.gotpl" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml.gotpl"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + values.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/values.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --values" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" --values "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --values=" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" --values="${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + helm flag" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" --set "service.type=NodePort" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + helm flag + --" {
    if on_cygwin; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint -f "${VALUES_PATH}" --set "service.type=NodePort" -- "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + pre decrypted secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    printf 'service:\n  port: 82' >"${VALUES_PATH}.dec"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + q flag" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -q lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + quiet flag" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --quiet lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + secrets.yaml + special path" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    create_chart "${SPECIAL_CHAR_DIR}"

    run "${HELM_BIN}" secrets lint "${SPECIAL_CHAR_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed.*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + invalid yaml" {
    VALUES="secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "Error: 1 chart(s) linted, 1 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --driver-args "--verbose" lint "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_success
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --driver-args "--verbose" lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + -a (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -a "--verbose" lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_DRIVER_ARGS=--verbose

    run env HELM_SECRETS_DRIVER_ARGS="${HELM_SECRETS_DRIVER_ARGS}" WSLENV="HELM_SECRETS_DRIVER_ARGS:${WSLENV}" \
        "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + --driver-args (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --driver-args "--verbose --output-type \"yaml\"" lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + -a (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -a "--verbose --output-type \"yaml\"" lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "lint: helm lint w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_DRIVER_ARGS="--verbose --output-type \"yaml\"" WSLENV="HELM_SECRETS_DRIVER_ARGS:${WSLENV}" \
        "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}
