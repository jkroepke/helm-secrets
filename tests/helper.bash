GIT_ROOT="$(git rev-parse --show-toplevel)"
export GIT_ROOT

TEST_DIR="${GIT_ROOT}/tests"
export TEST_DIR

TEST_HOME="${TEST_DIR}/.home"
export TEST_HOME

helm() {
    env HOME="${TEST_HOME}" helm "$@"
}

gpg() {
    env HOME="${TEST_HOME}" gpg "$@"
}

create_chart() {
    run helm create "${TEST_DIR}/tmp/$1"
    assert_success
    assert_output --partial "Creating ${TEST_DIR}/tmp/$1"

    if [ -f "${TEST_DIR}/tmp/$1/secrets.yaml" ]; then
        cp "${TEST_DIR}/assets/helm_vars/.sops.yaml" "${TEST_DIR}/tmp/$1/" >&2

        run helm secrets enc "${TEST_DIR}/tmp/$1/secrets.yaml"
        assert_success
    fi
}
