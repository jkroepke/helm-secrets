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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml.gotpl"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/values.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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

@test "template: helm template w/ chart + not-exists.yaml" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + http.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    touch "http.yaml"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "http.yaml" 2>&1

    assert_output --partial "port: 80"
    assert_success
    assert_file_not_exists "http.yaml.dec"
}

@test "template: helm template w/ chart + not-exists.yaml + HELM_SECRETS_IGNORE_MISSING_VALUES=false" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_IGNORE_MISSING_VALUES=false WSLENV="HELM_SECRETS_IGNORE_MISSING_VALUES:${WSLENV}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + not-exists.yaml + HELM_SECRETS_IGNORE_MISSING_VALUES=true" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_IGNORE_MISSING_VALUES=true WSLENV="HELM_SECRETS_IGNORE_MISSING_VALUES:${WSLENV}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    refute_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + not-exists.yaml + ignore errors" {
    VALUES="not-exists.yaml"
    VALUES_PATH="?${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    refute_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + not-exists.yaml + --ignore-missing-values" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env "${HELM_BIN}" secrets --ignore-missing-values template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    refute_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + not-exists.yaml + --ignore-missing-values false" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env "${HELM_BIN}" secrets --ignore-missing-values false template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + not-exists.yaml + --ignore-missing-values true" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env "${HELM_BIN}" secrets --ignore-missing-values true template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    refute_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + not-exists.yaml + --ignore-missing-values=false" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env "${HELM_BIN}" secrets --ignore-missing-values=false template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + not-exists.yaml + --ignore-missing-values=true" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env "${HELM_BIN}" secrets --ignore-missing-values=true template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" 2>&1

    refute_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + helm flag + --" {
    if on_cygwin; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    if [[ "${VALS_BIN}" = *".exe" ]]; then
        skip "Unix path w/ vals.exe"
    fi

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
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.empty.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    refute_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 80"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set service.port w/ error" {
    if ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set 'service.port=ref+file://notexists' 2>&1

    refute_output --partial "port: "
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set service.port" {
    if ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set service.port=ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set=service.port,podAnnotations.second" {
    if ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set=service.port=ref+echo://87,podAnnotations.second=value 2>&1

    assert_output --partial "port: 87"
    assert_output --partial "second: value"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set=service.port,podAnnotations.second + escape" {
    if on_windows || ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set=service.port=ref+echo://87,podAnnotations.second=va\\,lue 2>&1

    assert_output --partial "port: 87"
    assert_output --partial "second: va,lue"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set=podAnnotations.second + !" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set=podAnnotations.second='va!ue' 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "second: va!ue"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set-string service.port" {
    if ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set-string service.port=ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set-string=service.port" {
    if ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set-string=service.port=ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set-string=service.port + quotes in value" {
    if ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set-string='podAnnotations.quotes=ref+file://assets/values/vals/password.txt,service.port=ref+echo://87' 2>&1

    assert_output --partial "port: 87"
    assert_output --partial "quotes: 1234567!!\"§\$%&/(?=)(/&%\$§\"><;:_,;:_'''*'*\ndks"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + wrapper --set-string=service.port + quotes in value + escape" {
    if on_windows || ! is_backend "vals"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" \
        --set-string='podAnnotations.quotes=ref+file://assets/values/vals/password.txt,podAnnotations.escape=val\,ue,service.port=ref+echo://87' 2>&1

    assert_output --partial "port: 87"
    assert_output --partial "escape: val,ue"
    assert_output --partial "quotes: 1234567!!\"§\$%&/(?=)(/&%\$§\"><;:_,;:_'''*'*\ndks"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + --set-file service.port=secrets+literal://" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        --set-file service.port=secrets+literal://ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
}

@test "template: helm template w/ chart + --set-file=service.port=secrets+literal://" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        --set-file=service.port=secrets+literal://ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
}

@test "template: helm template w/ chart + --set-file=service.port=secrets+literal://vals!" {
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        --set-file=service.port=secrets+literal://vals!ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
}

@test "template: helm template w/ chart + --set-file=service.port=secrets+literal:// + quotes in value" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        --set-file='podAnnotations.quotes=secrets+literal://ref+file://assets/values/vals/password.txt,service.port=secrets+literal://ref+echo://88' 2>&1

    assert_output --partial "port: 88"
    assert_output --partial ":88'"
    assert_output --partial "quotes: 1234567!!\"§\$%&/(?=)(/&%\$§\"><;:_,;:_'''*'*\ndks"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + --set-file service.port=secrets+literal:// w/ error" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        --set-file 'service.port=secrets+literal://ref+file://notexists' 2>&1

    refute_output --partial "port: "
    assert_failure
}

@test "template: helm template w/ chart + secrets://secrets.yaml + --set-file secrets://file.txt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + --set-file secrets://file.json" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.json"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output -e 'hello\\?":.*\\?"fromextrafile'
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + --set-file=secrets://file.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://${VALUES_PATH}" \
        --set-file=podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello: fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + --set-file=secrets://file.properties" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.properties"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + --set-file=secrets://http://example.com/404.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://${VALUES_PATH}" --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Error while download url ${SET_FILE_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + wrapper + --set-file service.port=secrets+literal://" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        --set-file service.port=secrets+literal://ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
}

@test "template: helm template w/ chart + wrapper + --set-file=service.port=secrets+literal://" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        --set-file=service.port=secrets+literal://ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
}

@test "template: helm template w/ chart + wrapper + --set-file=service.port=secrets+literal://vals!" {
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        --set-file=service.port=secrets+literal://vals!ref+echo://87 2>&1

    assert_output --partial "port: 87"
    assert_success
}

@test "template: helm template w/ chart + wrapper + --set-file=service.port=secrets+literal:// + quotes in value" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        --set-file='podAnnotations.quotes=secrets+literal://ref+file://assets/values/vals/password.txt,service.port=secrets+literal://ref+echo://88' 2>&1

    assert_output --partial "port: 88"
    assert_output --partial ":88'"
    assert_output --partial "quotes: 1234567!!\"§\$%&/(?=)(/&%\$§\"><;:_,;:_'''*'*\ndks"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + wrapper + --set-file service.port=secrets+literal:// w/ error" {
    if ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        --set-file 'service.port=secrets+literal://ref+file://notexists' 2>&1

    refute_output --partial "port: "
    assert_failure
}

@test "template: helm template w/ chart + secrets://secrets.yaml + wrapper + --set-file secrets://file.txt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets://${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + wrapper + --set-file secrets://file.json" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.json"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets://${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output -e 'hello\\?":.*\\?"fromextrafile'
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + wrapper + --set-file=secrets://file.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets://${VALUES_PATH}" \
        --set-file=podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello: fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + wrapper + --set-file=secrets://file.properties" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.properties"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets://${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://secrets.yaml + wrapper + --set-file=secrets://http://example.com/404.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets://${VALUES_PATH}" --set-file podAnnotations.fromFile="secrets://${SET_FILE_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Error while download url ${SET_FILE_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + --set-file file.txt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" --set-file podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --set-file file.json" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.json"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" --set-file podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output -e 'hello\\?":.*\\?"fromextrafile'
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --set-file=file.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" --set-file=podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "hello: fromextrafile"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --set-file=file.properties" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.properties"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" --set-file podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --set-file=http://example.com/404.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" --set-file podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${SET_FILE_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + --set-file=http://example.com/404.yaml + HELM_SECRETS_IGNORE_MISSING_VALUES" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_IGNORE_MISSING_VALUES=true WSLENV="HELM_SECRETS_IGNORE_MISSING_VALUES:${WSLENV}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" --set-file podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output --partial 'fromFile: ""'
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + --set-file=http://example.com/404.yaml + ignore errors" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="?http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" \
        -f "${VALUES_PATH}" --set-file podAnnotations.fromFile="${SET_FILE_PATH}" 2>&1

    assert_output --partial 'fromFile: ""'
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + http://" {
    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + http://example.com/404.yaml" {
    VALUES="http://example.com/404.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES}"
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + git://" {
    if on_windows; then
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Decrypt: ${VALUES}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ chart + not-exists.yaml + secrets://" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        -f "secrets://${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + not-exists.yaml + secrets:// + HELM_SECRETS_IGNORE_MISSING_VALUES=false" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_IGNORE_MISSING_VALUES=false WSLENV="HELM_SECRETS_IGNORE_MISSING_VALUES:${WSLENV}" \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        -f "secrets://${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: ${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + not-exists.yaml + secrets:// + HELM_SECRETS_IGNORE_MISSING_VALUES=true" {
    VALUES="not-exists.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_IGNORE_MISSING_VALUES=true WSLENV="HELM_SECRETS_IGNORE_MISSING_VALUES:${WSLENV}" \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        -f "secrets://${VALUES_PATH}" 2>&1

    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + not-exists.yaml + secrets:// + ignore errors" {
    VALUES="not-exists.yaml"
    VALUES_PATH="?${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_IGNORE_MISSING_VALUES=true WSLENV="HELM_SECRETS_IGNORE_MISSING_VALUES:${WSLENV}" \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        -f "secrets://${VALUES_PATH}" 2>&1

    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://" {
    VALUES="secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http:// + HELM_SECRETS_URL_VARIABLE_EXPANSION=true" {
    if on_windows; then
        skip
    fi

    VALUES="secrets://https://raw.githubusercontent.com/\${GH_OWNER}/\${GH_REPO}/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="secrets://https://raw.githubusercontent.com/\${GH_OWNER}/\${GH_REPO}/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_URL_VARIABLE_EXPANSION:GH_OWNER:GH_REPO:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_URL_VARIABLE_EXPANSION=false \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://example.com/404.yaml" {
    VALUES="secrets://http://example.com/404.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://example.com/404.yaml + HELM_SECRETS_URL_VARIABLE_EXPANSION=true" {
    VALUES="secrets://http://example.com/404.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_URL_VARIABLE_EXPANSION=true "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" \
        -f "${VALUES_PATH}" 2>&1

    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://git://" {
    if on_windows; then
        skip
    fi

    VALUES="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_success
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1
    assert_success
    assert_output --partial "port: 91"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://sops!" {
    if on_windows; then
        skip
    fi

    VALUES="secrets+gpg-import://sops!${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${TEST_TEMP_DIR}/assets/values/sops/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1
    assert_success
    assert_output --partial "port: 91"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import:// + ignore errors" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="secrets+gpg-import://?${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/not-found.gpg_key.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "${VALUES_PATH}" 2>&1
    assert_success
    assert_output --partial "port: 80"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + wrapper + secrets+gpg-import://" {
    if on_windows || on_wsl || ! is_backend "sops"; then
        skip
    fi

    VALUES="secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"
    HELM_SECRETS_HELM_PATH="$(command -v "${HELM_BIN}")"

    create_chart "${TEST_TEMP_DIR}"
    cp "${GIT_ROOT}/scripts/wrapper/helm.sh" "${TEST_TEMP_DIR}/helm"
    chmod +x "${TEST_TEMP_DIR}/helm"

    run env -u TMPDIR HELM_SECRETS_HELM_PATH="${HELM_SECRETS_HELM_PATH}" HELM_SECRETS_WRAPPER_ENABLED=true PATH="${TEST_TEMP_DIR}:${PATH}" \
        "${TEST_TEMP_DIR}/helm" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 91"
    assert_success
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + wrapper + HELM_SECRETS_LOAD_GPG_KEYS=/private2.gpg" {
    if on_windows || on_wsl || ! is_backend "sops"; then
        skip
    fi

    VALUES="secrets://${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"
    HELM_SECRETS_HELM_PATH="$(command -v "${HELM_BIN}")"

    create_chart "${TEST_TEMP_DIR}"
    cp "${GIT_ROOT}/scripts/wrapper/helm.sh" "${TEST_TEMP_DIR}/helm"
    chmod +x "${TEST_TEMP_DIR}/helm"

    run env -u TMPDIR HELM_SECRETS_HELM_PATH="${HELM_SECRETS_HELM_PATH}" PATH="${TEST_TEMP_DIR}:${PATH}" HELM_SECRETS_WRAPPER_ENABLED=true HELM_SECRETS_LOAD_GPG_KEYS="${TEST_TEMP_DIR}/assets/gpg/private2.gpg" \
        "${TEST_TEMP_DIR}/helm" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 91"
    assert_success

    run env GNUPGHOME="${HOME}/.helm-secrets" gpgconf --kill gpg-agent
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + wrapper + HELM_SECRETS_LOAD_GPG_KEYS=/" {
    if on_windows || on_wsl || ! is_backend "sops"; then
        skip
    fi

    VALUES="secrets://${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.gpg_key.yaml"
    VALUES_PATH="${VALUES}"
    HELM_SECRETS_HELM_PATH="$(command -v "${HELM_BIN}")"

    create_chart "${TEST_TEMP_DIR}"
    cp "${GIT_ROOT}/scripts/wrapper/helm.sh" "${TEST_TEMP_DIR}/helm"
    chmod +x "${TEST_TEMP_DIR}/helm"

    run env -u TMPDIR GNUPGHOME="${HOME}/${BATS_TEST_NUMBER}" HELM_SECRETS_HELM_PATH="${HELM_SECRETS_HELM_PATH}" PATH="${TEST_TEMP_DIR}:${PATH}" HELM_SECRETS_WRAPPER_ENABLED=true HELM_SECRETS_LOAD_GPG_KEYS="${TEST_TEMP_DIR}/assets/gpg/" \
        "${TEST_TEMP_DIR}/helm" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "port: 91"
    assert_success

    run env GNUPGHOME="${HOME}/${BATS_TEST_NUMBER}" gpgconf --kill gpg-agent
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://git://" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.gpg_key.yaml?ref=main"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 91"
    assert_success
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import:// + HELM_SECRETS_ALLOW_GPG_IMPORT" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.gpg_key.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_GPG_IMPORT=false "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] secrets+gpg-import:// is not allowed in this context!"
    assert_failure
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import://" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.age.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 92"
    assert_success

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 92"
    assert_success
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import:// + ignore errors" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/not-found.age.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+age-import://?${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 80"
    assert_success

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://?${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import://git://" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.age.yaml?ref=main"
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
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.age.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_AGE_IMPORT=false "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] secrets+age-import:// is not allowed in this context!"
    assert_failure
}

@test "template: helm template w/ chart + --backend-args (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --backend-args "--verbose" template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial "port: 80"
    assert_success
}

@test "template: helm template w/ chart + some-secrets.yaml + --backend-args (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --backend-args "--verbose" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + -a (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
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

@test "template: helm template w/ chart + some-secrets.yaml + HELM_SECRETS_BACKEND_ARGS (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_BACKEND_ARGS=--verbose

    # shellcheck disable=SC2031 disable=SC2030
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --backend-args (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --backend-args "--verbose --output-type \"yaml\"" template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + -a (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
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

@test "template: helm template w/ chart + some-secrets.yaml + HELM_SECRETS_BACKEND_ARGS (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_BACKEND_ARGS="--verbose --output-type \"yaml\""
    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env WSLENV="${WSLENV}" HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "Data key recovered successfully"
    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 83"
    assert_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.symlink.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Values file '${VALUES_PATH}' is a symlink. Symlinks are not allowed."
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_SYMLINKS=true" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.symlink.yaml"
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
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Values filepath '${VALUES_PATH}' is an absolute path. Absolute paths are not allowed."
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=true" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/../values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output --partial "[helm-secrets] Values filepath '${VALUES_PATH}' contains '..'. Path traversal is not allowed."
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=true" {
    if on_windows || ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
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
    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template --repo https://jkroepke.github.io/helm-charts/ --version 1.0.3 values -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "global_secret: global_bar"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ remote chart + secrets.yaml + http:// + --set-file" {
    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template --repo https://jkroepke.github.io/helm-charts/ --version 1.0.3 values --set-file "content=${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "global_secret: global_bar"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ remote chart + secrets.yaml + http:// + query string url" {
    if on_windows; then
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?foo=b4r&test=true&arg1="
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template --repo https://jkroepke.github.io/helm-charts/ --version 1.0.3 values -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES//\?/\\?}"
    assert_output --partial "global_secret: global_bar"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ remote chart + secrets.yaml + http:// + query string url + --set-file" {
    if on_windows; then
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?foo=b4r&test=true&arg1="
    VALUES_PATH="${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template --repo https://jkroepke.github.io/helm-charts/ --version 1.0.3 values --set-file "content=${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES//\?/\\?}"
    assert_output --partial "global_secret: global_bar"
    assert_output --partial "[helm-secrets] Removed: "
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --evaluate-templates template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    refute_output --partial 'secret: "42"'
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates=true" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates=true template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates true" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates true template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_success
}

@test "template: helm template w/ chart + HELM_SECRETS_EVALUATE_TEMPLATES=true" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 HELM_SECRETS_EVALUATE_TEMPLATES=true WSLENV="HELM_SECRETS_EVALUATE_TEMPLATES:SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_success
}

@test "template: helm template w/ chart + wrapper + HELM_SECRETS_EVALUATE_TEMPLATES=true" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    cp "${GIT_ROOT}/scripts/wrapper/helm.sh" "${TEST_TEMP_DIR}/helm"
    chmod +x "${TEST_TEMP_DIR}/helm"

    # shellcheck disable=SC2030 disable=SC2031
    run env HELM_SECRETS_WRAPPER_ENABLED=true SECRET_VALUE=44 HELM_SECRETS_EVALUATE_TEMPLATES=true WSLENV="HELM_SECRETS_EVALUATE_TEMPLATES:SECRET_VALUE:${WSLENV:-}" \
        "${TEST_TEMP_DIR}/helm" template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates true + invalid syntax" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}" "false"

    cp -r "${TEST_ROOT}/assets/values/${HELM_SECRETS_BACKEND}/templates/error/." "${TEST_TEMP_DIR}/chart/templates/"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates true template "${TEST_TEMP_DIR}/chart" 2>&1

    refute_output --partial 'config: "42"'
    refute_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_output --partial 'vals error:'
    assert_failure
}

@test "template: helm template w/ chart + --evaluate-templates false" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates false template "${TEST_TEMP_DIR}/chart" 2>&1

    refute_output --partial 'config: "42"'
    refute_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates + --evaluate-templates-decode-secrets" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates --evaluate-templates-decode-secrets template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    assert_output --partial 'secret: NDI='
    assert_output --partial 'secret.env: NDQ='
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates + --evaluate-templates-decode-secrets=true" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates --evaluate-templates-decode-secrets=true template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    assert_output --partial 'secret: NDI='
    assert_output --partial 'secret.env: NDQ='
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates + --evaluate-templates-decode-secrets true" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates --evaluate-templates-decode-secrets true template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    assert_output --partial 'secret: NDI='
    assert_output --partial 'secret.env: NDQ='
    assert_success
}

@test "template: helm template w/ chart + --evaluate-templates + --evaluate-templates-decode-secrets false" {
    if on_wsl || ! is_backend "vals"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env SECRET_VALUE=44 WSLENV="SECRET_VALUE:${WSLENV:-}" \
        "${HELM_BIN}" secrets --evaluate-templates --evaluate-templates-decode-secrets false template "${TEST_TEMP_DIR}/chart" 2>&1

    assert_output --partial 'config: "42"'
    assert_output --partial 'config.env: "44"'
    refute_output --partial 'secret: "42"'
    refute_output --partial 'secret.env: "44"'
    assert_success
}

@test "template: helm template w/ chart + sops!secrets.yaml + wrapper --set vals!service.port" {
    VALUES="assets/values/sops/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "sops!${VALUES_PATH}" \
        --set "service.port=vals!ref+echo://87" 2>&1

    assert_output --partial "port: 87"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + sops!secrets.yaml + wrapper --set vals!service.port + HELM_SECRETS_ALLOWED_BACKENDS=vals,sops" {
    VALUES="assets/values/sops/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env HELM_SECRETS_ALLOWED_BACKENDS=vals,sops WSLENV="HELM_SECRETS_ALLOWED_BACKENDS:${WSLENV}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "sops!${VALUES_PATH}" \
        --set "service.port=vals!ref+echo://87" 2>&1

    assert_output --partial "port: 87"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + nonexists!secrets.yaml + wrapper --set nonexists!service.port" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "nonexists!${VALUES_PATH}" \
        --set "service.port=nonexists!ref+echo://87" 2>&1

    assert_output --partial "[helm-secrets] File does not exist: nonexists!${VALUES_PATH}"
    assert_failure
}

@test "template: helm template w/ chart + nonexists!secrets.yaml + wrapper --set nonexists!service.port + HELM_SECRETS_ALLOWED_BACKENDS=noop" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env HELM_SECRETS_ALLOWED_BACKENDS=noop WSLENV="HELM_SECRETS_ALLOWED_BACKENDS:${WSLENV}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "nonexists!${VALUES_PATH}" \
        --set "service.port=nonexists!ref+echo://87" 2>&1

    assert_output --partial "secret backend '${HELM_SECRETS_BACKEND}' not allowed"
    assert_failure
}

@test "template: helm template w/ chart + secrets://sops!secrets.yaml + --set-file secrets://sops!file.txt" {
    VALUES="assets/values/sops/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://sops!${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://sops!${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://vals!secrets.yaml + --set-file secrets://vals!file.txt" {
    VALUES="assets/values/vals/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://vals!${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://vals!${SET_FILE_PATH}" 2>&1

    assert_output --partial "port: 81"
    assert_output --partial "hello=fromextrafile"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://vals!secrets.yaml + --set-file secrets://vals!file.txt + HELM_SECRETS_ALLOWED_BACKENDS=noop" {
    VALUES="assets/values/vals/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env HELM_SECRETS_ALLOWED_BACKENDS=noop WSLENV="HELM_SECRETS_ALLOWED_BACKENDS:${WSLENV}" \
        "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://vals!${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://vals!${SET_FILE_PATH}" 2>&1

    assert_output --partial "secret backend '${HELM_SECRETS_BACKEND}' not allowed"
    assert_failure
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets://nonexists!secrets.yaml + --set-file secrets://nonexists!file.txt" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"
    SET_FILE_PATH="$(dirname "${VALUES_PATH}")/files/file.txt"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" template "$(_winpath "${TEST_TEMP_DIR}/chart")" -f "secrets://nonexists!${VALUES_PATH}" \
        --set-file podAnnotations.fromFile="secrets://nonexists!${SET_FILE_PATH}" 2>&1

    assert_output --partial "Can't find secret backend: nonexists"
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR=true" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2030 disable=SC2031
    run env HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR=true WSLENV="HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR:${WSLENV}" \
        "${HELM_BIN}" secrets template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_output -e "\[helm-secrets\] Removed: .*/secrets.yaml.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --decrypt-secrets-in-tmp-dir" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --decrypt-secrets-in-tmp-dir template "${TEST_TEMP_DIR}/chart" -f "${VALUES_PATH}" 2>&1

    assert_output -e "\[helm-secrets\] Decrypt: .*${VALUES}"
    assert_output --partial "port: 81"
    refute_output -e "\[helm-secrets\] Removed: .*${VALUES}.dec"
    assert_output -e "\[helm-secrets\] Removed: .*/secrets.yaml.dec"
    assert_success
    assert_file_not_exists "${VALUES_PATH}.dec"
}
