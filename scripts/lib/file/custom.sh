#!/usr/bin/env sh

_file_custom_exists() {
    _file_custom_get "$@" >/dev/null
}

_file_custom_get() {
    _tmp_file=$(mktemp)
    helm template "${SCRIPT_DIR}/lib/file/helm-values-getter" -f "${1}" >"${_tmp_file}"
    printf '%s' "${_tmp_file}"
}

_file_custom_put() {
    echo "Can't write to remote files!"
    exit 1
}
