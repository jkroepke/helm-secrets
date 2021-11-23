#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "template: helm template" {
    run helm secrets template
    assert_success
    assert_output --partial 'helm secrets [ OPTIONS ] template'
}

@test "template: helm template --help" {
    run helm secrets template --help
    assert_success
    assert_output --partial 'helm secrets [ OPTIONS ] template'
}

@test "template: helm template w/ chart" {
    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    assert_output --partial 'RELEASE-NAME-'
}

@test "template: helm template w/ chart + secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml.gotpl" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml.gotpl"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 85"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + values.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/values.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 85"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + helm flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + helm flag + --" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template -f "${FILE}" --set service.type=NodePort -- "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + pre decrypted secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    printf 'service:\n  port: 82' > "${FILE}.dec"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "port: 82"
    assert_file_exist "${FILE}.dec"

    run rm "${FILE}.dec"
    assert_success
}

@test "template: helm template w/ chart + secrets.yaml + q flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -q template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + quiet flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --quiet template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + special path" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${SPECIAL_CHAR_DIR}"

    run helm secrets template "${SPECIAL_CHAR_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + invalid yaml" {
    FILE="${TEST_TEMP_DIR}/secrets.yaml"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "Error: YAML parse error"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + secrets.yaml + http://" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi
    FILE="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
}

@test "template: helm template w/ chart + secrets.yaml + http://example.com/404.yaml" {
    if ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi
    FILE="http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] File does not exist: ${FILE}"
}

@test "template: helm template w/ chart + secrets.yaml + git://" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    FILE="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 81"
    assert_output --partial "[helm-secrets] Removed: "
}


@test "template: helm template w/ chart + secrets.yaml + sops://" {
    if on_windows ; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "sops://${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "template: helm template w/ chart + secrets.yaml + secret://" {
    if on_windows ; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "secret://${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "template: helm template w/ chart + secrets.yaml + secrets://" {
    if on_windows ; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "secrets://${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi
    FILE="secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http:// + HELM_SECRETS_URL_VARIABLE_EXPANSION=true" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi
    FILE="secrets://https://raw.githubusercontent.com/\${GH_OWNER}/\${GH_REPO}/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_URL_VARIABLE_EXPANSION=true GH_OWNER=jkroepke GH_REPO=helm-secrets helm template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http:// + HELM_SECRETS_URL_VARIABLE_EXPANSION=false" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi
    FILE="secrets://https://raw.githubusercontent.com/\${GH_OWNER}/\${GH_REPO}/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_URL_VARIABLE_EXPANSION=false helm template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://http://example.com/404.yaml" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi
    FILE="secrets://http://example.com/404.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_failure
}

@test "template: helm template w/ chart + secrets.yaml + secrets://git://" {
    if on_windows || ! is_driver "sops"; then
        # For vault its pretty hard to have a committed files with temporary seed of this test run
        skip
    fi

    FILE="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 81"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 91"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://git://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml?ref=main"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 91"
}

@test "template: helm template w/ chart + secrets.gpg_key.yaml + secrets+gpg-import:// + HELM_SECRETS_ALLOW_GPG_IMPORT" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_GPG_IMPORT=false helm template "${TEST_TEMP_DIR}/chart" -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secret] secrets+gpg-import:// is not allowed in this context!"
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 92"
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import://git://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml?ref=main"

    create_chart "${TEST_TEMP_DIR}"

    run helm template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${FILE}" 2>&1
    assert_success
    assert_output --partial "port: 92"
}

@test "template: helm template w/ chart + secrets.age.yaml + secrets+age-import:// + HELM_SECRETS_ALLOW_AGE_IMPORT" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_AGE_IMPORT=false helm template "${TEST_TEMP_DIR}/chart" -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secret] secrets+age-import:// is not allowed in this context!"
}

@test "template: helm template w/ chart + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --driver-args "--verbose" template "${TEST_TEMP_DIR}/chart" 2>&1
    assert_success
    assert_output --partial 'RELEASE-NAME-'
}

@test "template: helm template w/ chart + some-secrets.yaml + --driver-args (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --driver-args "--verbose" template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + -a (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -a "--verbose" template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (simple)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    HELM_SECRETS_DRIVER_ARGS=--verbose
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + --driver-args (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets --driver-args "--verbose --output-type \"yaml\"" template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + -a (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    run helm secrets -a "--verbose --output-type \"yaml\"" template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}

@test "template: helm template w/ chart + some-secrets.yaml + HELM_SECRETS_DRIVER_ARGS (complex)" {
    if ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"

    create_chart "${TEST_TEMP_DIR}"

    # shellcheck disable=SC2089
    HELM_SECRETS_DRIVER_ARGS="--verbose --output-type \"yaml\""
    # shellcheck disable=SC2090
    export HELM_SECRETS_DRIVER_ARGS

    run helm secrets template "${TEST_TEMP_DIR}/chart" -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "Data key recovered successfully"
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "port: 83"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert_file_not_exist "${FILE}.dec"
}
