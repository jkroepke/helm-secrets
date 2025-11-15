#!/usr/bin/env bash

sedi() {
    if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

if [ $# -lt 2 ] || [[ ! "${1}" =~ ^[0-9]\.[0-9]+\.[0-9]+$ ]] || [[ ! "${2}" =~ ^[0-9]\.[0-9]+\.[0-9]+$ ]]; then
    echo "Missing arguments."
    echo "$0 1.1.0 1.2.0"
    exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" ]]; then
    echo "Please checkout main"
    exit 1
fi

# https://stackoverflow.com/a/3278427/8087167
UPSTREAM='@{u}'
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Current branch is no up to date with origin. Please pull or push"
    exit 1
fi

sedi "s/version:.*/version: \"${1}\"/" "$(git rev-parse --show-toplevel)/plugin.yaml"
sedi "s/version:.*/version: \"${1}\"/" "$(git rev-parse --show-toplevel)/plugins/helm-secrets-cli/plugin.yaml"
sedi "s/version:.*/version: \"${1}\"/" "$(git rev-parse --show-toplevel)/plugins/helm-secrets-getter/plugin.yaml"
sedi "s/version:.*/version: \"${1}\"/" "$(git rev-parse --show-toplevel)/plugins/helm-secrets-post-renderer/plugin.yaml"
git commit -am "Release v${1}"
git tag --annotate -m "Release v${1}" "v${1}"

sedi "s/version:.*/version: \"${2}-dev\"/" "$(git rev-parse --show-toplevel)/plugin.yaml"
sedi "s/version:.*/version: \"${2}-dev\"/" "$(git rev-parse --show-toplevel)/plugins/helm-secrets-cli/plugin.yaml"
sedi "s/version:.*/version: \"${2}-dev\"/" "$(git rev-parse --show-toplevel)/plugins/helm-secrets-getter/plugin.yaml"
sedi "s/version:.*/version: \"${2}-dev\"/" "$(git rev-parse --show-toplevel)/plugins/helm-secrets-post-renderer/plugin.yaml"
git commit -am "Set next version"

git push --follow-tags --atomic
