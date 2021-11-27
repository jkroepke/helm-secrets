#!/usr/bin/env sh

set -euf

edit_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] edit <path to file>

Edit encrypted secrets

Decrypt encrypted file, edit and then encrypt

You can use plain sops to edit - https://github.com/mozilla/sops

Example:
  $ helm secrets edit <SECRET_FILE_PATH>
  or $ sops <SECRET_FILE_PATH>
  $ git add <SECRET_FILE_PATH>
  $ git commit
  $ git push

EOF
}

edit_helper() {
    dir=$(dirname "$1")
    file=$(basename "$1")

    if [ ! -d "${dir}" ]; then
        error 'Directory does not exist: %s' "${dir}"
    fi

    cd "$dir"
    driver_edit_file "yaml" "${file}"
}

edit() {
    echo "$1"
    if is_help "$1"; then
        edit_usage
        return
    fi

    file="$1"
    edit_helper "${file}"
}
