#!/usr/bin/env bats

load '../helper'
load '../bats/extensions/bats-support/load'
load '../bats/extensions/bats-assert/load'

@test "template: helm template" {
  run helm secrets template
  assert_success
  assert_output --partial 'helm secrets template'
}

@test "template: helm template --help" {
  run helm secrets template --help
  assert_success
  assert_output --partial 'helm secrets template'
}

@test "template: helm template w/ chart" {
  CHART=template
  create_chart "${CHART}"

  run helm secrets template "${TEST_DIR}/tmp/${CHART}" 2>&1
  assert_success
  refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial '# Source: template/templates/serviceaccount.yaml'
  refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "template: helm template w/ chart + secret file" {
  CHART=template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "secret: value"
  assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "template: helm template w/ chart + secret file + helm flag" {
  CHART=template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" --set image.pullPolicy=Always 2>&1
  assert_success
  assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "imagePullPolicy: Always"
  assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "template: helm template w/ chart + pre decrypted secret file" {
  CHART=template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  printf 'podAnnotations:\n  secret: othervalue' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"

  create_chart "${CHART}"

  run helm secrets template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  assert_output --partial "[helm-secrets] Decrypt skipped: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "secret: othervalue"
  assert [ -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]

  run rm "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert_success
}

@test "template: helm template w/ chart + secret file + q flag" {
  CHART=template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets -q template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "secret: value"
  refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "template: helm template w/ chart + secret file + quiet flag" {
  CHART=template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets --quiet template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  refute_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "secret: value"
  refute_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "template: helm template w/ chart + secret file + special path" {
  # CHART="l§\\i'!&@\$n%t"
  # shellcheck disable=SC2016
  CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "secret: value"
  assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "template: helm template w/ chart + invalid yaml" {
  CHART=template

  mkdir -p "${TEST_DIR}/tmp/${CHART}" >&2
  printf 'replicaCount: |\n  a:' > "${TEST_DIR}/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets template "${TEST_DIR}/tmp/${CHART}" -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml" 2>&1
  assert_failure
  assert_output --partial "[helm-secrets] Decrypt: ${TEST_DIR}/tmp/${CHART}/secrets.yaml"
  assert_output --partial "Error: YAML parse error"
  assert_output --partial "[helm-secrets] Removed: ${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "${TEST_DIR}/tmp/${CHART}/secrets.yaml.dec" ]
}
