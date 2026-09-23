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

@test "helm-plugin: helm version without v prefix" {
    mkdir -p "${TEST_TEMP_DIR}/plugin/scripts/lib"
    cp "${GIT_ROOT}/scripts/lib/common.sh" "${TEST_TEMP_DIR}/plugin/scripts/lib/common.sh"
    cp "${GIT_ROOT}/plugin.yaml" "${TEST_TEMP_DIR}/plugin/plugin.yaml"

    cat >"${TEST_TEMP_DIR}/helm-no-v" <<'EOF'
#!/usr/bin/env sh
if [ "$1" = "version" ] && [ "$2" = "--short" ]; then
    printf '%s\n' '4.3.0+gbec5b06'
    exit 0
fi
exit 1
EOF
    chmod +x "${TEST_TEMP_DIR}/helm-no-v"

    run env HELM_BIN="${TEST_TEMP_DIR}/helm-no-v" HELM_PLUGIN_DIR="${TEST_TEMP_DIR}/plugin" sh -c '. "$HELM_PLUGIN_DIR/scripts/lib/common.sh"; _helm_version'
    assert_success
    assert_output '4'
}
