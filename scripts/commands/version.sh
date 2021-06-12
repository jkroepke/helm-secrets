#!/usr/bin/env sh

set -euf

version() {
    grep version "${SCRIPT_DIR}/../plugin.yaml" | cut -d'"' -f2
}
