#!/usr/bin/env sh

set -euf

is_help() {
    case "$1" in
    -h | --help | help)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

on_macos() {
    [ "$(uname)" = "Darwin" ]
}

load_secret_driver() {
    driver="${1}"
    if [ -f "${SCRIPT_DIR}/drivers/${driver}.sh" ]; then
        # shellcheck source=scripts/drivers/sops.sh
        . "${SCRIPT_DIR}/drivers/${driver}.sh"
    else
        # Allow to load out of tree drivers.
        if [ ! -f "${driver}" ]; then

            echo "Can't find secret driver: ${driver}"
            exit 1
        fi

        # shellcheck disable=SC2034
        HELM_SECRETS_SCRIPT_DIR="${SCRIPT_DIR}"

        # shellcheck source=tests/assets/custom-driver.sh
        . "${driver}"
    fi
}

_regex_escape() {
    # This is a function because dealing with quotes is a pain.
    # http://stackoverflow.com/a/2705678/120999
    sed -e 's/[]\/()$*.^|[]/\\&/g'
}

_trap() {
    # https://stackoverflow.com/a/85903/8087167
    if LC_ALL=C type _trap_hook >/dev/null; then
        _trap_hook
    fi

    rm -rf "${TMPDIR}"
}

if on_macos; then
    _mktemp() { mktemp -t "${TMPDIR_SUFFIX}/" "$@"; }
else
    _mktemp() { mktemp "$@"; }
fi
