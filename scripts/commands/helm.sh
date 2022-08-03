#!/usr/bin/env sh

set -euf

# shellcheck source=scripts/commands/dec.sh
. "${SCRIPT_DIR}/commands/dec.sh"

helm_command_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] $1

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

decrypted_files=$(_mktemp)

_trap_hook() {
    if [ -s "${decrypted_files}" ]; then
        if [ "${QUIET}" = "false" ]; then
            echo >&2
            # shellcheck disable=SC2016
            xargs -0 -n1 sh -c 'rm "$1" && printf "[helm-secrets] Removed: %s\n" "$1"' sh >&2 <"${decrypted_files}"
        else
            xargs -0 rm >&2 <"${decrypted_files}"
        fi

        rm "${decrypted_files}"
    fi
}

helm_wrapper() {
    argc=$#
    j=0

    while [ $j -lt $argc ]; do
        case "$1" in
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

            if ! real_file=$(_file_get "${file}"); then
                fatal 'File does not exist: %s' "${file}"
            fi

            file_dec="$(_file_dec_name "${real_file}")"
            if [ -f "${file_dec}" ]; then
                set -- "$@" "$(_helm_winpath "${file_dec}")"

                if [ "${QUIET}" = "false" ]; then
                    printf '[helm-secrets] Decrypt skipped: %s\n' "${file}" >&2
                fi
            else
                if decrypt_helper "${real_file}"; then
                    set -- "$@" "$(_helm_winpath "${file_dec}")"
                    printf '%s\0' "${file_dec}" >>"${decrypted_files}"

                    if [ "${QUIET}" = "false" ]; then
                        printf '[helm-secrets] Decrypt: %s\n' "${file}" >&2
                    fi
                else
                    set -- "$@" "$(_helm_winpath "${real_file}")"
                fi
            fi
            ;;
        *)
            if [ -d "$1" ]; then
                set -- "$@" "$(_helm_winpath "${1}")"
            else
                set -- "$@" "$1"
            fi
            ;;
        esac

        shift
        j=$((j + 1))
    done

    "${HELM_BIN}" ${TILLER_HOST:+--host "$TILLER_HOST"} "$@"
}

helm_command() {
    if [ $# -lt 2 ] || is_help "$2"; then
        helm_command_usage "${1:-"[helm command]"}"
        return
    fi

    helm_wrapper "$@"
}
