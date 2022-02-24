#!/usr/bin/env bash


_sed_i() {
    # MacOS syntax is different for in-place
    if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

_shasum() {
    # MacOS have shasum, others have sha1sum
    if command -v shasum >/dev/null; then
        shasum "$@"
    else
        sha1sum "$@"
    fi
}

_gpg() {
    # cygwin does not have an alias
    if command -v gpg2 >/dev/null; then
        gpg2 "$@"
    elif command -v gpg.exe >/dev/null; then
        gpg.exe "$@"
    else
        gpg "$@"
    fi
}

_gpgconf() {
    if command -v gpgconf.exe >/dev/null; then
        gpgconf.exe "$@"
    else
        gpgconf "$@"
    fi
}

_git() {
    if command -v git.exe >/dev/null; then
        git.exe "$@"
    else
        git "$@"
    fi
}

_helm() {
    if command -v helm.exe >/dev/null; then
        helm.exe "$@"
    else
        helm "$@"
    fi
}
