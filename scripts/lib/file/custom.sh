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
        fatal "helm template command errored on value '%s'" "${1}"
    fi

    if ! _sed_i -e '1,3d' -e 's/^  //g' "${_tmp_file}"; then
        fatal "sed command errored on value '%s'" "${1}"
    fi

    if ! truncate -s-1 "${_tmp_file}"; then
        fatal "truncate command errored on value '%s'" "${1}"
    fi

    printf '%s' "${_tmp_file}"
}
