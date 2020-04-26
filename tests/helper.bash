GIT_ROOT="$(git rev-parse --show-toplevel)"
export GIT_ROOT

TEST_HOME="${GIT_ROOT}/tests/.home"
export TEST_HOME

helm() {
    env HOME="${TEST_HOME}" helm "$@"
}

gpg() {
    env HOME="${TEST_HOME}" gpg "$@"
}

create_chart() {
    run helm create "tests/tmp/$1"
    assert_success
    assert_output --partial "Creating tests/tmp/$1"

    if [ -f "tests/tmp/$1/secrets.yaml" ]; then
        cp "tests/assets/helm_vars/.sops.yaml" "tests/tmp/$1/" >&2

        run helm secrets enc "tests/tmp/$1/secrets.yaml"
        assert_success
    fi
}
