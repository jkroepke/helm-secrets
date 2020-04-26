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
  refute_output --partial "[helm-secrets] Decrypt: tests/tmp/${CHART}/secrets.yaml"
  assert_output --partial '1 chart(s) linted, 0 chart(s) failed'
  refute_output --partial "[helm-secrets] Removed: tests/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "tests/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "lint: helm lint w/ chart + secret file" {
  CHART=lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  assert_output --partial "[helm-secrets] Decrypt: tests/tmp/${CHART}/secrets.yaml"
  assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
  assert_output --partial "[helm-secrets] Removed: tests/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "tests/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "lint: helm lint w/ chart + secret file + q flag" {
  CHART=lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets -q lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  refute_output --partial "[helm-secrets] Decrypt: tests/tmp/${CHART}/secrets.yaml"
  assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
  refute_output --partial "[helm-secrets] Removed: tests/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "tests/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "lint: helm lint w/ chart + secret file + quiet flag" {
  CHART=lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets --quiet lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  refute_output --partial "[helm-secrets] Decrypt: tests/tmp/${CHART}/secrets.yaml"
  assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
  refute_output --partial "[helm-secrets] Removed: tests/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "tests/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "lint: helm lint w/ chart + secret file + special path" {
  # CHART="l§\\i'!&@\$n%t"
  # shellcheck disable=SC2016
  CHART=$(printf '%s' 'a@b§c!d\$e\f(g)h=i^j😀')/lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'podAnnotations:\n  secret: value' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_success
  assert_output --partial "[helm-secrets] Decrypt: tests/tmp/${CHART}/secrets.yaml"
  assert_output --partial "1 chart(s) linted, 0 chart(s) failed"
  assert_output --partial "[helm-secrets] Removed: tests/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "tests/tmp/${CHART}/secrets.yaml.dec" ]
}

@test "lint: helm lint w/ chart + invalid yaml" {
  CHART=lint

  mkdir -p "tests/tmp/${CHART}" >&2
  printf 'replicaCount: |\n  a:' > "tests/tmp/${CHART}/secrets.yaml"

  create_chart "${CHART}"

  run helm secrets lint "tests/tmp/${CHART}" -f "tests/tmp/${CHART}/secrets.yaml" 2>&1
  assert_failure
  assert_output --partial "[helm-secrets] Decrypt: tests/tmp/${CHART}/secrets.yaml"
  assert_output --partial "Error: 1 chart(s) linted, 1 chart(s) failed"
  assert_output --partial "[helm-secrets] Removed: tests/tmp/${CHART}/secrets.yaml.dec"
  assert [ ! -f "tests/tmp/${CHART}/secrets.yaml.dec" ]
}
