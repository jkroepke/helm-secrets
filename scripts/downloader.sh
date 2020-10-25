#!/usr/bin/env sh

SCRIPT_DIR="$(dirname "$0")"

echo "-----------" >> "${SCRIPT_DIR}/dump.txt"
echo "$@" >> "${SCRIPT_DIR}/dump.txt"
