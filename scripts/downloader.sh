#!/usr/bin/env sh

# https://helm.sh/docs/topics/plugins/#downloader-plugins
# It's always the 4th parameter
file=$(printf '%s' "${4}" | sed -e 's!.*://!!')

exec sops --decrypt --input-type "yaml" --output-type "yaml" "${file}"
