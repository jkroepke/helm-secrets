#!/usr/bin/env bash

export WSLENV="${WSLENV:-}"

setup() {
    {
        # shellcheck disable=SC2164
        cd "${TEST_ROOT}"

        TEST_TEMP_DIR="${BATS_TEST_TMPDIR}"
        export TEST_TEMP_DIR

        # copy assets
        cp -a "${TEST_ROOT}/assets" "${TEST_TEMP_DIR}/"
        if ! on_windows; then
            # shellcheck disable=SC2016
            SPECIAL_CHAR_DIR="${TEST_TEMP_DIR}/$(printf '%s' 'a@b§c!d\$e \f(g)h=i^j😀')"
            mkdir "${SPECIAL_CHAR_DIR}"
            cp -a "${TEST_ROOT}/assets" "${SPECIAL_CHAR_DIR}/"
        fi

        ln -s "${TEST_ROOT}/assets/values/sops/.sops.yaml" "${TEST_TEMP_DIR}"
    } >&2
}

teardown() {
    {
        # https://stackoverflow.com/a/13864829/8087167
        if [ -n "${RELEASE+x}" ]; then
            "${HELM_BIN}" del "${RELEASE}" || true
        fi
    } >&2
}

create_chart() {
    {
        if [ "${2:-}" == "false" ]; then
            cp -r "${HELM_CACHE}/chart/${HELM_SECRETS_BACKEND}" "${1}/chart"
        else
            ln -s "${HELM_CACHE}/chart/${HELM_SECRETS_BACKEND}" "${1}/chart"
        fi
    } >&2
}

is_backend() {
    [[ "${HELM_SECRETS_BACKEND}" == "${1}" ]]
}

on_windows() {
    # shellcheck disable=SC2154
    ! [[ "${_uname}" == "Darwin" || "${_uname}" == "Linux" ]] || on_wsl
}

on_linux() {
    [[ "${_uname}" == "Linux" ]]
}

on_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

on_cygwin() {
    [[ "${_uname}" == "CYGWIN"* ]]
}

_winpath() {
    if on_wsl; then
        touch "${1}"
        printf '%s' "$(wslpath -w "${1}")"
    elif on_cygwin; then
        touch "${1}"
        printf '%s' "$(cygpath -w -l "${1}")"
    else
        printf '%s' "${1}"
    fi
}
