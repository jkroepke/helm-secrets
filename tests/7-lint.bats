#!/usr/bin/env bats

load helper
load 'bats/extensions/bats-support/load'
load 'bats/extensions/bats-assert/load'

@test "lint: helm lint" {
  run helm secrets lint
  assert_success
  assert_output --partial 'helm secrets lint'
}

@test "lint: helm lint --help" {
  run helm secrets lint --help
  assert_success
  assert_output --partial 'helm secrets lint'
}

@test "lint: helm lint w/ chart" {
  CHART=lint
  create_chart "${CHART}"

  run helm secrets lint "tests/tmp/${CHART}" 2>&1
  assert_success
  assert_output --partial '1 chart(s) linted, 0 chart(s) failed'
  assert_output --partial '[helm-secrets] Remove decrypted files:'
}

@test "lint: helm lint w/ chart and secret file" {
  CHART=lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  assert_output --partial '[helm-secrets] Decrypt: tests/tmp/lint/secrets.yaml'
  assert_output --partial '1 chart(s) linted, 0 chart(s) failed'
  assert_output --partial '[helm-secrets] Remove decrypted files:'
}

@test "lint: helm lint w/ chart and invalid yaml" {
  CHART=lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'replicaCount: |\n  a:' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_failure
  assert_output --partial '[helm-secrets] Decrypt: tests/tmp/lint/secrets.yaml'
  assert_output --partial 'Error: 1 chart(s) linted, 1 chart(s) failed'
  # @TOOD: Run cleanup if errors appears
  # assert_output --partial '[helm-secrets] Remove decrypted files:'
}
