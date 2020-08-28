#!/usr/bin/env sh

set -eu

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/commands/dec.sh"

helm_command_usage() {
    cat <<EOF
helm secrets $1 [ --driver <driver> | -d <driver> ] [ --quiet | -q ]

This is a wrapper for "helm [command]". It will detect -f and
--values options, and decrypt any encrypted *.yaml files before running "helm
[command]".

Example:
  $ helm secrets upgrade <HELM UPGRADE OPTIONS>
  $ helm secrets lint <HELM LINT OPTIONS>

Typical usage:
  $ helm secrets upgrade i1 stable/nginx-ingress -f values.test.yaml -f secrets.test.yaml
  $ helm secrets lint ./my-chart -f values.test.yaml -f secrets.test.yaml

EOF
}

helm_wrapper_cleanup() {
    if [ -s "${decrypted_files}" ]; then
        if [ "${QUIET}" = "false" ]; then
            echo >/dev/stderr
            # shellcheck disable=SC2016
            xargs -0 -n1 sh -c 'rm "$1" && printf "[helm-secrets] Removed: %s\n" "$1"' sh >/dev/stderr <"${decrypted_files}"
        else
            xargs -0 rm >/dev/stderr <"${decrypted_files}"
        fi
    fi

    rm "${decrypted_files}"
}

helm_wrapper() {
    decrypted_files=$(mktemp)

    argc=$#
    j=0

    #cleanup on-the-fly decrypted files
    trap helm_wrapper_cleanup EXIT

    while [ $j -lt $argc ]; do
        case "$1" in
        --)
            # skip --, and what remains are the cmd args
            set -- "$1"
            shift
            break
            ;;
        -f | --values | --values=?*)
            case "$1" in
            *=*)
                file="${1#*=}"

                set -- "$@" "${1%%=*}"
                ;;
            *)
                file="${2}"

                set -- "$@" "$1"
                shift
                j=$((j + 1))
                ;;
            esac

            file_dec="$(file_dec_name "${file}")"
            if [ -f "${file_dec}" ]; then
                set -- "$@" "$file_dec"

                if [ "${QUIET}" = "false" ]; then
                    printf '[helm-secrets] Decrypt skipped: %s' "${file}" >/dev/stderr
                fi
            else
                if decrypt_helper "${file}"; then
                    set -- "$@" "$file_dec"
                    printf '%s\0' "${file_dec}" >>"${decrypted_files}"

                    if [ "${QUIET}" = "false" ]; then
                        printf '[helm-secrets] Decrypt: %s' "${file}" >/dev/stderr
                    fi
                else
                    set -- "$@" "$file"
                fi
            fi
            ;;
        *)
            set -- "$@" "$1"
            ;;
        esac

        shift
        j=$((j + 1))
    done

    if [ "${QUIET}" = "false" ]; then
        echo >/dev/stderr
    fi

    "${HELM_BIN}" ${TILLER_HOST:+--host "$TILLER_HOST"} "$@"
}

helm_command() {
    if [ $# -lt 2 ] || is_help "$2"; then
        helm_command_usage "${1:-"[helm command]"}"
        return
    fi

    helm_wrapper "$@"
}
