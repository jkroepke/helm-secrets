#!/usr/bin/env sh

set -euf

_file_custom_exists() {
    _file_custom_get "$@" >/dev/null
}

_file_custom_get() {
    _tmp_file=$(_mktemp)
    GETTER_CHART_PATH="$(_helm_winpath "${SCRIPT_DIR}/lib/file/helm-values-getter")"
    VALUES="$(_helm_winpath "${1}")"

    if ! "${HELM_BIN}" template "${GETTER_CHART_PATH}" --set-file "content=${VALUES}" >"${_tmp_file}"; then
        exit 1
    fi

    _sed_i -e '1,3d' -e 's/^  //g' "${_tmp_file}"
    printf '%s' "${_tmp_file}"
}
