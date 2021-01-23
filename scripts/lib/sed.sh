#!/usr/bin/env sh

set -euf

# MacOS syntax is different for in-place
# https://unix.stackexchange.com/a/92907/433641
case $(sed --help 2>&1) in
*BusyBox* | *GNU*) _sed_i() { sed -i "$@"; } ;;
*) _sed_i() { sed -i '' "$@"; } ;;
esac
