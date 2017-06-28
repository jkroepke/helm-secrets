#!/bin/bash

# colors
RED='\033[0;31m'
#GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NOC='\033[0m'

# set you own options
if [ ! "${DECRYPT_CHARTS}" ];
then
    DECRYPT_CHARTS=false
fi
if [ ! "${KMS_USE}" ];
then
    KMS_USE=true
fi

HELM_CMD="/usr/local/bin/helm"
MATCH_ARGS="[-.*]"
MATCH_FILES_ARGS=".*secrets.y*"
DEC_SUFFIX=".dec"
COUNT_CHART_FAILED=0
COUNT_FILES_FAILED=0
COUNT_CHART=0
COUNT_FILES=0

decrypt_chart() {
  local chart="$file"
  if [[ ! "$chart" =~ $MATCH_ARGS ]];
  then
      if [ -d "$chart" ];
      then
          if [ ! "$DECRYPT_CHARTS" = true ];
          then
            "$HELM_CMD" secrets dec-deps "$chart"
          fi
          echo -e "${YELLOW}>>>>>>${NOC} ${BLUE}Dependencies build and package${NOC}"
          "$HELM_CMD" dep build "$chart" && "$HELM_CMD" package "$chart"
          (( COUNT_CHART++ ))
      else
          (( COUNT_CHART_FAILED++ ))
          return
      fi
  fi
}

decrypt_helm_vars() {
  if [[ "$file" =~ $MATCH_FILES_ARGS ]];
  then
    if [ ! "$AWS_PROFILE" ] && [ "$KMS_USE" = true ];
    then
      echo -e "${RED}!!! If KMS used need AWS_PROFILE env variable set !!!${NOC}"
      exit 1
      echo ""
    fi
    if [ -f "$file" ];
      then
          echo -e "${YELLOW}>>>>>>${NOC} ${BLUE}Decrypt${NOC}"
          "$HELM_CMD" secrets dec "$file" 2>/dev/null
          (( COUNT_FILES++ ))
      else
          (( COUNT_FILES_FAILED++ ))
          return
    fi
  fi
}

function cleanup {
if [ "$1" == "install" ] || [ "$1" == "upgrade" ] || [ "$1" == "rollback" ];
then
    echo -e "${YELLOW}>>>>>>${NOC} ${BLUE}Cleanup${NOC}"
    for file in "${@}"
      do
        if [[ "$file" =~ $MATCH_FILES_ARGS ]];
        then
          "$HELM_CMD" secrets clean "${file}${DEC_SUFFIX}" 2>/dev/null
        fi
      done
fi
}

function helm_cmd {
    echo ""
    $(echo "${HELM_CMD} $*" | sed -e 's/secrets.yaml/secrets.yaml.dec/g')
    local status=$?
    if [ "$status" -ne 0 ]; then
        echo ""
        cleanup "$@"
        exit 1
    else
        echo ""
        cleanup "$@"
        exit 0
    fi
}

if [ "$1" == "install" ] || [ "$1" == "upgrade" ] || [ "$1" == "rollback" ];
  then
    for file in "$@"
      do
         decrypt_helm_vars "$file"
         decrypt_chart "$file"
    done
fi

if [ "$COUNT_CHART" -eq 0 ] && [ "$COUNT_FILES" -eq 0 ] && [ "$COUNT_CHART_FAILED" -gt 0 ] && [ "$COUNT_FILES_FAILED" -gt 0 ];
then
    echo -e "${RED}Error no secrets found. No secret files in chart or secrets files defined${NOC}"
    exit 1
fi

# Run helm
helm_cmd "$@"
