#!/usr/bin/env sh

set -euf

is_help() {
    case "$1" in
    -h | --help | help)
        true
        ;;
    *)
        false
        ;;
    esac
}

log() {
    if [ $# -le 1 ]; then
        printf '[helm-secrets] %s\n' "${1:-}" >&2
    else
        format="${1}"
        shift

        # shellcheck disable=SC2059
        printf "[helm-secrets] $format\n" "$@" >&2
    fi
}

error() {
    log "$@"
}

fatal() {
    error "$@"

    exit 1
}

_regex_escape() {
    # This is a function because dealing with quotes is a pain.
    # http://stackoverflow.com/a/2705678/120999
    sed -e 's/[]\/()$*.^|[]/\\&/g'
}

_trap() {
    if command -v _trap_hook >/dev/null; then
        _trap_hook
    fi

    if command -v _trap_kill_gpg_agent >/dev/null; then
        _trap_kill_gpg_agent
    fi

    rm -rf "${TMPDIR}"
}

# MacOS syntax and behavior is different for mktemp
# https://unix.stackexchange.com/a/555214
_mktemp() {
    # ksh/posh - @: parameter not set
    # https://stackoverflow.com/a/35242773
    if [ $# -eq 0 ]; then
        mktemp "${TMPDIR}/XXXXXX"
    else
        mktemp "$@" "${TMPDIR}/XXXXXX"
    fi
}

_gpg_load_keys() {
    export GNUPGHOME="${HOME}/.secrets"
    if [ ! -d "${GNUPGHOME}" ]; then
        mkdir -p "${HOME}/.secrets"

        for key in ${LOAD_GPG_KEYS}; do
            if [ -d "${key}" ]; then
                for file in "${key}"/*; do
                    gpg --batch --no-permission-warning --quiet --import "${file}"
                done
            elif [ -f "${key}" ]; then
                gpg --batch --no-permission-warning --quiet --import "${key}"
            fi
        done
    fi
}

on_wsl() { false; }
on_cygwin() { false; }
_sed_i() { sed -i "$@"; }
_winpath() { printf '%s' "${1}"; }
_helm_winpath() { printf '%s' "${1}"; }

case "$(uname -s)" in
CYGWIN*)
    on_cygwin() { true; }
    _winpath() {
        if [ "${2:-0}" = "1" ]; then
            printf '%s' "${1}" | cygpath -w -l -f - | sed -e 's!\\!\\\\!g'
        else
            printf '%s' "${1}" | cygpath -w -l -f -
        fi
    }
    _helm_winpath() { _winpath "$@"; }
    ;;
Darwin)
    case $(sed --help 2>&1) in
    *BusyBox* | *GNU*) ;;
    *) _sed_i() { sed -i '' "$@"; } ;;
    esac
    ;;
*)
    # Check of WSL
    if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
        on_wsl() { true; }
        _winpath() {
            touch "${1}"
            if [ "${2:-0}" = "1" ]; then
                wslpath -w "${1}" | sed -e 's!\\!\\\\!g'
            else
                wslpath -w "${1}"
            fi
        }

        case "${HELM_BIN}" in
        *.exe) _helm_winpath() { _winpath "$@"; } ;;
        esac
    fi
    ;;
esac
