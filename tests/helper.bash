GIT_ROOT="$(git rev-parse --show-toplevel)"
export GIT_ROOT

TEST_DIR="${GIT_ROOT}/tests"
export TEST_DIR

TEST_HOME="${TEST_DIR}/.home"
export TEST_HOME

setup() {
    TEST_TEMP_DIR="$(temp_make --prefix 'helm-secrets-')"
}

teardown() {
    temp_del "$TEST_TEMP_DIR"
}

helm() {
    env HOME="${TEST_HOME}" helm "$@"
}

gpg() {
    env HOME="${TEST_HOME}" gpg "$@"
}

create_chart() {
    run helm create "${TEST_DIR}/.tmp/$1"
    assert_success
    assert_output --partial "Creating ${TEST_DIR}/.tmp/$1"

    if [ -f "${TEST_DIR}/.tmp/$1/secrets.yaml" ]; then
        cp "${TEST_DIR}/assets/helm_vars/.sops.yaml" "${TEST_DIR}/.tmp/$1/" >&2

        run helm secrets enc "${TEST_DIR}/.tmp/$1/secrets.yaml"
        assert_success
    fi
}

tests_setup() {
  # Reset test environment
  run git checkout HEAD -- "${TEST_DIR}/assets/helm_vars/"
  assert_success

  run rm -rf "${TEST_HOME}" "${TEST_DIR}/.tmp/"
  assert_success

  run mkdir -p "${TEST_HOME}" "${TEST_DIR}/.tmp/"
  assert_success

  run find "${TEST_DIR}/assets" \( -name '*.yaml.*' -o -name 'secrets.tmp.yaml' \) -delete
  assert_success

  run gpg --batch --import "${TEST_DIR}/assets/pgp/projectx.asc"
  assert_success

  run gpg --batch --import "${TEST_DIR}/assets/pgp/projecty.asc"
  assert_success
}

tests_cleanup() {
  # Reset test environment
  run git checkout HEAD -- tests/assets/helm_vars/
  assert_success
}
