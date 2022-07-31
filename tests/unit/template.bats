#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "template: helm template" {
    run "${HELM_BIN}" secrets template

    assert_output --partial 'helm secrets [ OPTIONS ] template'
    assert_success
}

@test "template: helm template --help" {
    run "${HELM_BIN}" secrets template --help

    assert_output --partial 'helm secrets [ OPTIONS ] template'
    assert_success
}

@test "template: helm template w/ chart" {
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --values" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" --values "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --values=" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" --values="${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml.gotpl" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml.gotpl"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 85"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_file_not_exists "${VALUES_PATH}.dec"
    assert_success
}

@test "template: helm template w/ chart + some-secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_file_not_exists "${VALUES_PATH}.dec"
    assert_success
}

@test "template: helm template w/ chart + values.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/values.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 85"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --values" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" --values "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --values=" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" --values="${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + helm flag" {
    if on_wsl; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" --set "service.type=NodePort" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + helm flag + --" {
    if on_wsl || on_cygwin; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template -f "${VALUES_PATH}" --set "service.type=NodePort" -- "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + pre decrypted secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    printf 'service:\n  port: 82' >"${VALUES_PATH}.dec"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt skipped: .*${VALUES}"
    assert_output --partial "port: 82"
    assert_success
    assert_file_exists "${VALUES_PATH}.dec"

    run rm "${VALUES_PATH}.dec"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + q flag" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -q template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + quiet flag" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --quiet template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + special path" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    create_chart "${SPECIAL_CHAR_DIR}"

    run "${HELM_BIN}" secrets template "${SPECIAL_CHAR_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + invalid yaml" {
    VALUES="secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "Error: YAML parse error"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.empty.yaml" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.empty.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 80"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + http://" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + http://example.com/404.yaml" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="http://example.com/404.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES}"
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + git://" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Decrypt: ${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + sops://" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "sops://${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secret://" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secret://${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secrets://" {
    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http:// + HELM_SECRETS_URL_VARIABLE_EXPANSION=true" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="secrets://https://raw.githubusercontent.com/\${GH_OWNER}/\${GH_REPO}/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_URL_VARIABLE_EXPANSION:GH_OWNER:GH_REPO:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_URL_VARIABLE_EXPANSION=true GH_OWNER=jkroepke GH_REPO=helm-secrets \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http:// + HELM_SECRETS_URL_VARIABLE_EXPANSION=false" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="secrets://https://raw.githubusercontent.com/\${GH_OWNER}/\${GH_REPO}/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_URL_VARIABLE_EXPANSION:GH_OWNER:GH_REPO:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_URL_VARIABLE_EXPANSION=false \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://example.com/404.yaml" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="secrets://http://example.com/404.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://git://" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1
    assert_success
    assert_output --partial "port: 91"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + wrapper + secrets+gpg-import://" {
    if ! on_linux || on_wsl || ! is_driver "sops"; then
        skip
    fi

    VALUES="secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"
    HELM_SECRETS_HELM_PATH="$(command -v "${HELM_BIN}")"

    create_chart "${TEST_TEMP_DIR}"
    printf '#!/usr/bin/env sh\nexec %s secrets "$@"' "${HELM_SECRETS_HELM_PATH}" >"${TEST_TEMP_DIR}/helm"
    chmod +x "${TEST_TEMP_DIR}/helm"

    run env HELM_SECRETS_HELM_PATH="${HELM_SECRETS_HELM_PATH}" PATH="${TEST_TEMP_DIR}:${PATH}" \
        "${TEST_TEMP_DIR}/helm" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 91"
    assert_success
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://git://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 91"
    assert_success
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import:// + HELM_SECRETS_ALLOW_GPG_IMPORT" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_GPG_IMPORT=false "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] secrets+gpg-import:// is not allowed in this context!"
    assert_failure
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 92"
    assert_success

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 92"
    assert_success
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import://git://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 92"
    assert_success

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 92"
    assert_success
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import:// + HELM_SECRETS_ALLOW_AGE_IMPORT" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_AGE_IMPORT=false "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] secrets+age-import:// is not allowed in this context!"
    assert_failure
}

@test "template: helm template w/ chart + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --driver-args "--verbose" template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + some-secrets.yaml + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --driver-args "--verbose" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + -a (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -a "--verbose" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_DRIVER_ARGS=--verbose

    # shellcheck disable=SC2031 disable=SC2030
    WSLENV="HELM_SECRETS_DRIVER_ARGS:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_DRIVER_ARGS="${HELM_SECRETS_DRIVER_ARGS}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --driver-args (complex)" {
    if on_wsl || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --driver-args "--verbose --output-type \"yaml\"" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + -a (complex)" {
    if on_wsl || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -a "--verbose --output-type \"yaml\"" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_DRIVER_ARGS="--verbose --output-type \"yaml\""
    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_DRIVER_ARGS:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_DRIVER_ARGS="${HELM_SECRETS_DRIVER_ARGS}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.symlink.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Values file '${VALUES_PATH}' is a symlink. Symlinks are not allowed."
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_SYMLINKS=true" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.symlink.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_SYMLINKS=true "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Values filepath '${VALUES_PATH}' is an absolute path. Absolute paths are not allowed."
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=true" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=true "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/../values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Values filepath '${VALUES_PATH}' contains '..'. Path traversal is not allowed."
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=true" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=true "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ remote chart + secrets.yaml + http://" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template --repo https://jkroepke.github.io/helm-charts/ --version 1.0.3 values -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}
