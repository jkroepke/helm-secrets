#!/usr/bin/env sh

set -euf

_file_custom_exists() {
    _file_custom_get "$@" >/dev/null
}

_file_custom_get() {
    GETTER_CHART_PATH="$(_helm_winpath "${SCRIPT_DIR}/lib/file/helm-values-getter")"
    VALUES="$(_helm_winpath "${1}")"

    if ! VALUES_CONTENT=$("${HELM_BIN}" template "${GETTER_CHART_PATH}" --set-file "content=${VALUES}"); then
        exit 1
    fi

    printf '%s' "${VALUES_CONTENT}" | sed -e '1,3d' -e 's/^  //g'
}
