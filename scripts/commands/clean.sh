#!/usr/bin/env sh

set -euf

clean_usage() {
    cat <<EOF
helm secrets clean <dir with secrets>

Clean all decrypted files if any exist

It removes all decrypted ${DEC_SUFFIX} files in the specified directory
(recursively) if they exist.

EOF
}

clean() {
    if is_help "$1"; then
        clean_usage
        return
    fi

    basedir="$1"

    if [ ! -d "${basedir}" ]; then
        printf 'Directory does not exist: %s\n' "${basedir}"
        exit 1
    fi

    find "$basedir" -type f -name "*${DEC_SUFFIX}" -exec rm -v {} \;
}
