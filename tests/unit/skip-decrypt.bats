#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "skip-decrypt: helm lint w/ chart + secrets.yaml + --skip-decrypt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --skip-decrypt lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES}"
    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "skip-decrypt: helm lint w/ chart + secrets.yaml + --skip-decrypt=true" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --skip-decrypt=true lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES}"
    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "skip-decrypt: helm lint w/ chart + secrets.yaml + --skip-decrypt=false (should decrypt)" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --skip-decrypt=false lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    refute_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES}"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "skip-decrypt: helm lint w/ chart + secrets.yaml + HELM_SECRETS_SKIP_DECRYPT=true" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_SKIP_DECRYPT=true WSLENV="HELM_SECRETS_SKIP_DECRYPT:${WSLENV}" \
        "${HELM_BIN}" secrets lint "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES}"
    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "skip-decrypt: helm template w/ chart + secrets.yaml + --skip-decrypt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --skip-decrypt template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES}"
    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "skip-decrypt: helm template w/ chart + multiple secrets.yaml + --skip-decrypt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    VALUES2="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES2_PATH="${TEST_TEMP_DIR}/${VALUES2}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --skip-decrypt template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" -f "${VALUES2_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES}"
    assert_output -e "\[helm-secrets\] Decrypt skipped \(--skip-decrypt\): .*${VALUES2}"
    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_file_not_exists "${VALUES_PATH}.dec"
    assert_file_not_exists "${VALUES2_PATH}.dec"
}

@test "skip-decrypt: helm secrets decrypt + --skip-decrypt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --skip-decrypt decrypt "${VALUES_PATH}" 2>&1

    # Should output encrypted content (contains sops metadata or ENC markers)
    assert_output --partial 'sops'
    refute_output --partial 'global_secret: global_bar'
    assert_success
}

@test "skip-decrypt: helm secrets decrypt + --skip-decrypt=true" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --skip-decrypt=true decrypt "${VALUES_PATH}" 2>&1

    # Should output encrypted content
    assert_output --partial 'sops'
    refute_output --partial 'global_secret: global_bar'
    assert_success
}

@test "skip-decrypt: helm secrets decrypt + HELM_SECRETS_SKIP_DECRYPT=true" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run env HELM_SECRETS_SKIP_DECRYPT=true WSLENV="HELM_SECRETS_SKIP_DECRYPT:${WSLENV}" \
        "${HELM_BIN}" secrets decrypt "${VALUES_PATH}" 2>&1

    # Should output encrypted content
    assert_output --partial 'sops'
    refute_output --partial 'global_secret: global_bar'
    assert_success
}

@test "skip-decrypt: helm secrets decrypt + --skip-decrypt=false (should decrypt)" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --skip-decrypt=false decrypt "${VALUES_PATH}" 2>&1

    # Should output decrypted content
    assert_output --partial 'global_secret: global_bar'
    assert_success
}
