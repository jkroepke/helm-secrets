#!/usr/bin/env sh

set -eu

edit_usage() {
    cat <<EOF
helm secrets edit [ --driver <driver> | -d <driver> ] <path to file>

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
    file="$1"

    if [ ! -e "${file}" ]; then
        printf 'File does not exist: %s\n' "${file}"
        exit 1
    fi

    driver_edit_file "yaml" "${file}"
}

edit() {
    file="$1"
    edit_helper "${file}"
}
