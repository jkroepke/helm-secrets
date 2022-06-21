#!/usr/bin/env bats

load '../lib/helper'
load '../lib/create_encrypted_file'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'
load '../bats/extensions/bats-file/load'

@test "install: helm install" {
    run "${HELM_BIN}" secrets install
    assert_success
    assert_output --partial 'helm secrets [ OPTIONS ] install'
}

@test "install: helm install --help" {
    run "${HELM_BIN}" secrets install --help
    assert_success
    assert_output --partial 'helm secrets [ OPTIONS ] install'
}

@test "install: helm install w/ chart" {
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt:"
    assert_output --partial 'STATUS: deployed'
    refute_output --partial "[helm-secrets] Removed:"

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
}

@test "install: helm install w/ chart + secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + some-secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 83"
}

@test "install: helm install w/ chart + some-secrets.yaml + --values" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 83"
}

@test "install: helm install w/ chart + some-secrets.yaml + --values=" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/some-secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks --values="${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 83"
}

@test "install: helm install w/ chart + secrets.yaml + helm flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" --set service.type=NodePort 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
    assert_output --partial "type: NodePort"
}

@test "install: helm install w/ chart + pre decrypted secrets.yaml" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    printf 'service:\n  port: 82' >"${FILE}.dec"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt skipped: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert [ -f "${FILE}.dec" ]

    run rm "${FILE}.dec"
    assert_success

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 82"
}

@test "install: helm install w/ chart + secrets.yaml + q flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets -q install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + quiet flag" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets --quiet install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    refute_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    refute_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + special path" {
    FILE="${SPECIAL_CHAR_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${SPECIAL_CHAR_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${SPECIAL_CHAR_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + invalid yaml" {
    FILE="${TEST_TEMP_DIR}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_encrypted_file 'replicaCount: |\n  a:'

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "YAML parse error on"
    assert_output --partial "[helm-secrets] Removed: ${FILE}.dec"
    assert [ ! -f "${FILE}.dec" ]
}

@test "install: helm install w/ chart + secrets.yaml + sops://" {
    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "sops://${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + http://" {
    FILE="https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: "
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + git://" {
    if on_windows; then
        skip
    fi

    FILE="git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" secrets install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "[helm-secrets] Decrypt: ${FILE}"
    assert_output --partial "STATUS: deployed"
    assert_output --partial "[helm-secrets] Removed: "
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + secrets://http://" {
    FILE="secrets://https://raw.githubusercontent.com/jkroepke/helm-secrets/main/tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.yaml + secrets://git://" {
    if on_windows; then
        skip
    fi

    FILE="secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/${HELM_SECRETS_DRIVER}/secrets.yaml?ref=main"
    RELEASE="install-$(date +%s)-${SEED}"
    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 81"
}

@test "install: helm install w/ chart + secrets.gpg_key.yaml + secrets+gpg-import://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+gpg-import://${TEST_TEMP_DIR}/assets/gpg/private2.gpg?${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 91"
}

@test "install: helm install w/ chart + secrets.gpg_key.yaml + secrets+gpg-import-kubernetes://name#key" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"
    kubectl create secret generic gpg-key --from-file=private2.gpg="${TEST_TEMP_DIR}/assets/gpg/private2.gpg" >&2

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+gpg-import-kubernetes://gpg-key#private2.gpg?${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 91"
}

@test "install: helm install w/ chart + secrets.gpg_key.yaml + secrets+gpg-import-kubernetes://namespace/name#key" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"
    kubectl -n kube-system create secret generic gpg-key --from-file=private3.gpg="${TEST_TEMP_DIR}/assets/gpg/private2.gpg" >&2

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+gpg-import-kubernetes://kube-system/gpg-key#private3.gpg?${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 91"
}

@test "install: helm install w/ chart + secrets.gpg_key.yaml + secrets+gpg-import-kubernetes://namespace/name#key + HELM_SECRETS_ALLOW_GPG_IMPORT_KUBERNETES" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_GPG_IMPORT_KUBERNETES=false helm install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+gpg-import-kubernetes://kube-system/gpg-key#private3.gpg?${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] secrets+gpg-import-kubernetes:// is not allowed in this context!"
}

@test "install: helm install w/ chart + secrets.gpg_key.yaml + secrets+gpg-import-kubernetes://namespace/non-exists#key" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.gpg_key.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+gpg-import-kubernetes://kube-system/non-exists#private3.gpg?${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Couldn't get kubernetes secret kube-system/non-exists"
}

@test "install: helm install w/ chart + secrets.age.yaml + secrets+age-import://" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+age-import://${TEST_TEMP_DIR}/assets/age/key.txt?${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 92"
}

@test "install: helm install w/ chart + secrets.age.yaml + secrets+age-import-kubernetes://name#key" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"
    kubectl create secret generic age-key --from-file=key.txt="${TEST_TEMP_DIR}/assets/age/key.txt" >&2

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+age-import-kubernetes://age-key#key.txt?${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 92"
}

@test "install: helm install w/ chart + secrets.age.yaml + secrets+age-import-kubernetes://namespace/name#key" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"
    kubectl -n kube-system create secret generic age-key --from-file=keys.txt="${TEST_TEMP_DIR}/assets/age/key.txt" >&2

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+age-import-kubernetes://kube-system/age-key#keys.txt?${FILE}" 2>&1
    assert_success
    assert_output --partial "STATUS: deployed"
    assert [ ! -f "${FILE}.dec" ]

    run kubectl get svc -o yaml -l "app.kubernetes.io/name=chart,app.kubernetes.io/instance=${RELEASE}"
    assert_success
    assert_output --partial "port: 92"
}

@test "install: helm install w/ chart + secrets.age.yaml + secrets+age-import-kubernetes://namespace/name#key + HELM_SECRETS_ALLOW_AGE_IMPORT_KUBERNETES" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run env HELM_SECRETS_ALLOW_AGE_IMPORT_KUBERNETES=false helm install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+age-import-kubernetes://kube-system/age-key#keys.txt?${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] secrets+age-import-kubernetes:// is not allowed in this context!"
}

@test "install: helm install w/ chart + secrets.age.yaml + secrets+age-import-kubernetes://namespace/non-exists#key" {
    if on_windows || ! is_driver "sops"; then
        skip
    fi

    FILE="${TEST_TEMP_DIR}/assets/values/${HELM_SECRETS_DRIVER}/secrets.age.yaml"
    RELEASE="install-$(date +%s)-${SEED}"

    create_chart "${TEST_TEMP_DIR}"

    run "${HELM_BIN}" install "${RELEASE}" "${TEST_TEMP_DIR}/chart" --no-hooks -f "secrets+age-import-kubernetes://kube-system/non-exists#keys.txt?${FILE}" 2>&1
    assert_failure
    assert_output --partial "[helm-secrets] Couldn't get kubernetes secret kube-system/non-exists"
}
