#!/usr/bin/env bash

define_binaries() {
    # MacOS have shasum, others have sha1sum
    if command -v shasum >/dev/null; then
        export SHA1SUM_BIN=shasum
    else
        export SHA1SUM_BIN=sha1sum
    fi

    # cygwin does not have an alias
    if command -v gpg2 >/dev/null; then
        export GPG_BIN=gpg2
    elif command -v gpg.exe >/dev/null; then
        export GPG_BIN=gpg.exe
    else
        export GPG_BIN=gpg
    fi

    if command -v gpgconf.exe >/dev/null; then
        export GPGCONF_BIN=gpgconf.exe
    else
        export GPGCONF_BIN=gpgconf
    fi

    if command -v git.exe >/dev/null; then
        export GIT_BIN=git.exe
    else
        export GIT_BIN=git
    fi

    if command -v helm.exe >/dev/null; then
        export HELM_BIN=helm.exe
    else
        export HELM_BIN=helm
    fi

    if command -v sops.exe >/dev/null; then
        export SOPS_BIN=sops.exe
    else
        export SOPS_BIN=sops
    fi
}
