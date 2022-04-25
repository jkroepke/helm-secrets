#!/usr/bin/env sh

set -euf

_file_custom_exists() {
    _file_custom_get "$@" >/dev/null
}

_file_custom_get() {
    _tmp_file=$(_mktemp)

    GETTER_CHART_PATH="${SCRIPT_DIR}/lib/file/helm-values-getter"

    if on_wsl; then
        GETTER_CHART_PATH="$(_convert_path "${GETTER_CHART_PATH}")"
    fi

    if ! "${HELM_BIN}" template "${GETTER_CHART_PATH}" -f "${1}" >"${_tmp_file}"; then
        exit 1
    fi

    _sed_i '/^# Source: /d' "${_tmp_file}"
    printf '%s' "${_tmp_file}"
}

_file_custom_put() {
    echo "Can't write to remote files!"
    exit 1
}
