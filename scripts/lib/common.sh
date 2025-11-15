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

    if [ -n "${_GNUPGHOME+x}" ]; then
        if [ -f "${_GNUPGHOME}/.helm-secrets" ]; then
            # On CentOS 7, there is no kill option
            case $(gpgconf --help 2>&1) in
            *--kill*)
                gpgconf --kill gpg-agent
                ;;
            esac
        fi
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
    _GNUPGHOME=$(_mktemp -d)
    touch "${_GNUPGHOME}/.helm-secrets"

    export GNUPGHOME="${_GNUPGHOME}"
    for key in ${LOAD_GPG_KEYS}; do
        if [ -d "${key}" ]; then
            set +f
            for file in "${key%%/}/"*; do
                gpg --batch --no-permission-warning --quiet --import "${file}"
            done
            set -f
        else
            gpg --batch --no-permission-warning --quiet --import "${key}"
        fi
    done
}

on_wsl() { false; }
on_cygwin() { false; }
_sed_i() { sed -i "$@"; }
_winpath() { printf '%s' "${1}"; }
_helm_winpath() { printf '%s' "${1}"; }
_helm_bin() { printf '%s' "${HELM_BIN}"; }

case "$(uname -s)" in
CYGWIN* | MINGW64_NT*)
    on_cygwin() { true; }
    _winpath() {
        if [ "${2:-0}" = "1" ]; then
            printf '%s' "${1}" | cygpath -w -l -f - | sed -e 's!\\!\\\\!g'
        else
            printf '%s' "${1}" | cygpath -w -l -f -
        fi
    }

    _helm_winpath() { _winpath "$@"; }
    _helm_bin() { _winpath "${HELM_BIN}"; }

    _sed_i 's!  - command: .*!  - command: "scripts/wrapper/run.cmd downloader"!' "${HELM_PLUGIN_DIR}/plugin.yaml"
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

        # We are on a Linux VM, but helm.exe (Win32) is called
        case "${HELM_BIN}" in
        *.exe)
            _helm_winpath() { _winpath "$@"; }

            _sed_i 's!  - command: .*!  - command: "scripts/wrapper/run.cmd downloader"!' "${HELM_PLUGIN_DIR}/plugin.yaml"
            ;;
        esac
    fi
    ;;
esac

if on_cygwin; then
    HELM_BIN="$(cygpath -u "${HELM_BIN}")"
fi

case $("${HELM_BIN}" version --short) in
v2*)
    _helm_version() { echo 2; }
    ;;
v3*)
    _helm_version() { echo 3; }
    ;;
v4*)
    _helm_version() { echo 4; }
    ;;
*)
    fatal "Unsupported helm version: $(${HELM_BIN} version --short)"
    ;;
esac
