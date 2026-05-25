#!/usr/bin/env bats

load '../lib/helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "decrypt: helm decrypt" {
    run "${HELM_BIN}" secrets decrypt
    assert_failure
    assert_output --partial 'Error: secrets file required.'
}

@test "decrypt: helm decrypt --help" {
    run "${HELM_BIN}" secrets decrypt --help
    assert_output --partial 'Decrypt secrets'
    assert_success
}

@test "decrypt: File not exits" {
    run "${HELM_BIN}" secrets decrypt nonexists
    assert_failure
    assert_output --partial '[helm-secrets] File does not exist: nonexists'
}

@test "decrypt: Decrypt secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.trailing-newline.raw" {
    if ! is_backend "sops"; then
        skip
    fi
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.trailing-newline.raw"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    COMPARE="assets/values/${HELM_SECRETS_BACKEND}/secrets.trailing-newline.dec.raw"
    COMPARE_PATH="${TEST_TEMP_DIR}/${COMPARE}"
    COMPARE_VALUE=$(cat "${COMPARE_PATH}" && printf _)
    COMPARE_VALUE=${COMPARE_VALUE%_}

    OUTPUT=$("${HELM_BIN}" secrets decrypt "${VALUES_PATH}" && printf _)
    OUTPUT=${OUTPUT%_}
    assert_equal "$OUTPUT" "$COMPARE_VALUE"
}

@test "decrypt: Decrypt inline secrets.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt -i "${VALUES_PATH}"
    assert_success

    assert_file_contains "${VALUES_PATH}" 'global_secret: global_bar'
}

@test "decrypt: Decrypt inline secrets.trailing-newline.raw (appends missing newline)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.trailing-newline.raw"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt -i "${VALUES_PATH}"
    assert_success

    # The inline-decrypted file must end with a newline (exercises the printf '\n' branch)
    run sh -c "tail -c1 '${VALUES_PATH}' | wc -l | tr -d ' '"
    assert_output "1"
}
@test "decrypt: inline decrypt appends trailing newline when backend omits it" {
    # Regression test for https://github.com/jkroepke/helm-secrets/issues/714
    # Uses a mock backend that writes decrypted content WITHOUT a trailing newline,
    # reproducing what sops --output does for block-scalar YAML in affected versions.
    # This test FAILS without the printf '\n' fix in decrypt_helper (decrypt.sh).

    local mock_backend="${TEST_TEMP_DIR}/no-newline-backend.sh"
    local mock_file="${TEST_TEMP_DIR}/mock-secret.yaml"

    # Encrypted file: content matches _BACKEND_REGEX so is_file_encrypted returns true.
    printf 'secret_key: HELM_SECRETS_MOCK_TOKEN\n' >"${mock_file}"

    # Write the mock backend. It sources _custom.sh (so _custom_backend_is_file_encrypted
    # uses _BACKEND_REGEX correctly) then overrides _custom_backend_decrypt_file to write
    # output WITHOUT a trailing newline — simulating the sops --output stripping bug.
    cat >"${mock_backend}" <<'MOCKEOF'
#!/usr/bin/env sh
_BACKEND_REGEX='HELM_SECRETS_MOCK_TOKEN'
# shellcheck source=scripts/lib/backends/_custom.sh
. "${HELM_SECRETS_SCRIPT_DIR}/lib/backends/_custom.sh"
# Override: write WITHOUT trailing newline to reproduce the sops stripping bug.
_custom_backend_decrypt_file() {
    # type=$1  input=$2  output=$3 (empty = stdout)
    if [ -n "${3}" ]; then
        printf 'secret_key: decrypted_value' >"${3}"
    else
        printf 'secret_key: decrypted_value'
    fi
}
MOCKEOF
    chmod +x "${mock_backend}"

    # Use --backend flag so load_secret_backend sets HELM_SECRETS_SCRIPT_DIR before sourcing.
    run "${HELM_BIN}" secrets --backend "${mock_backend}" decrypt -i "${mock_file}"
    assert_success

    # The fix in decrypt_helper must have appended a newline after the backend wrote without one.
    # Without the fix in decrypt.sh, tail -c1 | wc -l returns 0 and the test FAILS.
    run sh -c "tail -c1 '${mock_file}' | wc -l | tr -d ' '"
    assert_output "1"

    assert_file_contains "${mock_file}" "secret_key: decrypted_value"
}

@test "decrypt: Decrypt secrets.yaml.gotpl" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml.gotpl"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_tpl'
    assert_success
}

@test "decrypt: Decrypt some-secrets.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt some-secrets.windows.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/some-secrets.windows.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt values.yaml" {
    VALUES="assets/values/${HELM_SECRETS_BACKEND}/values.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"

    assert_output -e "\[helm-secrets\] File is not encrypted: .*${VALUES}"
    assert_failure
}

@test "decrypt: Decrypt secrets.yaml + special char directory name" {
    if on_windows; then
        skip "Skip on Windows"
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${SPECIAL_CHAR_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + http://" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run "${HELM_BIN}" secrets decrypt "${VALUES}"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + http://example.com/404.yaml" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="http://example.com/404.yaml"

    run "${HELM_BIN}" secrets decrypt "${VALUES}"
    assert_failure
    assert_output --partial "[helm-secrets] File does not exist: ${VALUES}"
}

@test "decrypt: Decrypt secrets.yaml + git://" {
    if ! is_backend "sops" || on_windows; then
        skip
    fi

    VALUES="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml?ref=main"

    run "${HELM_BIN}" secrets decrypt "${VALUES}"
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + --backend-args (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --backend-args "--verbose" decrypt "${VALUES_PATH}"
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + -a (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets -a "--verbose" decrypt "${VALUES_PATH}"
    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + HELM_SECRETS_BACKEND_ARGS (simple)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_BACKEND_ARGS=--verbose

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + --backend-args (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets --backend-args "--verbose --output-type \"yaml\"" decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + -a (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    run "${HELM_BIN}" secrets -a "--verbose --output-type \"yaml\"" decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml + HELM_SECRETS_BACKEND_ARGS (complex)" {
    if ! is_backend "sops"; then
        skip
    fi

    VALUES="assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"
    VALUES_PATH="${TEST_TEMP_DIR}/${VALUES}"

    HELM_SECRETS_BACKEND_ARGS="--verbose --output-type \"yaml\""

    # shellcheck disable=SC2030 disable=SC2031
    WSLENV="HELM_SECRETS_BACKEND_ARGS:${WSLENV:-}"

    run env HELM_SECRETS_BACKEND_ARGS="${HELM_SECRETS_BACKEND_ARGS}" WSLENV="${WSLENV}" \
        "${HELM_BIN}" secrets decrypt "${VALUES_PATH}"

    assert_output --partial "Data key recovered successfully"
    assert_output --partial 'global_secret: global_bar'
    assert_success
}

@test "decrypt: Decrypt secrets.yaml in terraform mode" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_BACKEND}/secrets.yaml"

    run "${HELM_BIN}" secrets decrypt --terraform "${FILE}"

    # assert that there are no new lines in the base64
    assert_output --regexp '\{"content_base64":"([A-Za-z0-9=]*)"\}'

    assert_success
}
