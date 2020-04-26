TEST_HOME="$(git rev-parse --show-toplevel)/tests/.home"
export TEST_HOME

helm () {
	env HOME="${TEST_HOME}" helm "$@"
}

gpg () {
	env HOME="${TEST_HOME}" gpg "$@"
}
