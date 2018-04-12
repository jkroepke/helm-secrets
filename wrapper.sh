#!/usr/bin/env bash

set -ueo pipefail
shopt -s extglob

# Redirect fds so that output to &3 is real stdout, and &1 goes to stderr
# instead; this prevents accidentially intermixing with what helm sends to
# stdout.
exec 3>&1
exec 1>&2

# colors
RED='\033[0;31m'
#GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NOC='\033[0m'

# constants
SUPPORTED_COMMANDS="@(install|upgrade|rollback|template|diff|lint)"

MATCH_FILES_ARGS=".*secrets*.y*"
DEC_SUFFIX=".dec.yaml"
COUNT_FILES_FAILED=0
COUNT_FILES=0

CURRENT_COMMAND="${1:-}"

case "$0" in
    helm-wrapper)
        WRAPPER_PATH="$(command -v helm-wrapper)"
        ;;
    *)
        WRAPPER_PATH="$0"
        ;;
esac

HELM_CMD="$(dirname $WRAPPER_PATH)/helm"

decrypt_helm_vars() {
    local file="$1"
    if [[ $file =~ secrets(\.[^.]+)?\.yaml && ! $file =~ \.dec\.yaml$ ]]
    then
        (( ++COUNT_FILES ))
	if [[ -f $file ]]
	then
            echo -e "${YELLOW}>>>>>>${NOC} ${BLUE}Decrypt${NOC}"
            "$HELM_CMD" secrets dec "$file"
	else
            (( ++COUNT_FILES_FAILED ))
            return
	fi
    fi
}

function cleanup {
    case "${CURRENT_COMMAND}" in
	$SUPPORTED_COMMANDS)
	    echo -e "${YELLOW}>>>>>>${NOC} ${BLUE}Cleanup${NOC}"
	    for file in "$@"
	    do
		if [[ -d $file  ]]							
		then
		    "$HELM_CMD" secrets clean "$file"
		fi
	    done
    esac
}

function helm_cmd {
    echo ""
    trap 'cleanup $@' INT TERM EXIT
    $(echo "${HELM_CMD} $*" | sed -E -e 's/(secrets(\.[^.]*)?)\.yaml/\1'"$DEC_SUFFIX"'/g') >&3
    local status=$?
    if [[ $status == 0 ]]
    then
        echo ""
        cleanup "$@"
        exit 1
    else
        echo ""
        cleanup "$@"
        exit 0
    fi
}

case "${CURRENT_COMMAND}" in
    $SUPPORTED_COMMANDS)
        for file in "$@"
        do
            decrypt_helm_vars "$file"
        done
        ;;
esac

if [[ $COUNT_FILES > 0 && $COUNT_FILES_FAILED > 0 ]]
then
    echo -e "${RED}Some secrets files could not be decrypted, not found${NOC}"
    exit 1
fi

# Run helm
helm_cmd "$@"
