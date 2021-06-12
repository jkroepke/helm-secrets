#!/usr/bin/env sh

set -euf

clean_usage() {
    cat <<EOF
helm secrets clean <dir with secrets>

Clean all decrypted files if any exist

It removes all decrypted files in the specified directory
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
        error 'Directory does not exist: %s\n' "${basedir}"
    fi

    if [ "${DEC_PREFIX}" != "" ] && [ "${DEC_SUFFIX}" != "" ]; then
        find "$basedir" -type f -name "${DEC_PREFIX}*${DEC_SUFFIX}" -exec rm -v {} \;
    elif [ "${DEC_PREFIX}" != "" ]; then
        find "$basedir" -type f -name "${DEC_PREFIX}*" -exec rm -v {} \;
    elif [ "${DEC_SUFFIX}" != "" ]; then
        find "$basedir" -type f -name "*${DEC_SUFFIX}" -exec rm -v {} \;
    fi
}
