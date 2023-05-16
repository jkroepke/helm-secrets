#!/usr/bin/env sh

_noop_backend_is_file_encrypted() {
    false
}

_noop_backend_edit_file() {
    # shellcheck disable=SC2034
    type="${1}"
    input="${2}"

    "${EDITOR:-vi}" "${input}"
}
