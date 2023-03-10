#!/usr/bin/env sh

set -euf

# shellcheck source=scripts/commands/decrypt.sh
. "${SCRIPT_DIR}/commands/decrypt.sh"

helm_command_usage() {
    cat <<EOF
helm secrets [ OPTIONS ] $1

This is a wrapper for "helm [command]". It will detect -f and
--values options, and decrypt any encrypted *.yaml files before running "helm
[command]".

Example:
  $ helm secrets <HELM SECRETS OPTIONS> upgrade <HELM UPGRADE OPTIONS>
  $ helm secrets <HELM SECRETS OPTIONS> lint <HELM LINT OPTIONS>

Typical usage:
  $ helm secrets upgrade i1 stable/nginx-ingress -f values.test.yaml -f secrets.test.yaml
  $ helm secrets -b vals lint ./my-chart -f values.test.yaml -f secrets.test.yaml

EOF
}

decrypted_file_list=$(_mktemp)

_trap_hook() {
    if [ -s "${decrypted_file_list}" ]; then
        if [ "${QUIET}" = "false" ]; then
            echo >&2
            # shellcheck disable=SC2016
            xargs -0 -n1 sh -c 'rm "$1" && printf "[helm-secrets] Removed: %s\n" "$1"' sh >&2 <"${decrypted_file_list}"
        else
            xargs -0 rm >&2 <"${decrypted_file_list}"
        fi

        rm "${decrypted_file_list}"
    fi
}

helm_wrapper() {
    argc=$#
    j=0

    while [ $j -lt $argc ]; do
        case "$1" in
        --set | --set=?* | --set-string | --set-string=?* | --set-json | --set-json=?*)
            _1="${1}"

            case "${_1}" in
            --set=* | --set-string=* | --set-json=*)
                literals="${_1#*=}"

                set -- "$@" "${_1%%=*}"
                ;;
            *)
                literals="${2}"

                set -- "$@" "$1"
                shift
                j=$((j + 1))
                ;;
            esac

            decrypted_literals=""

            IFS='
'

            for literal in $(printf '%s' "${literals}" | sed -E 's/([^\\]),/\1\n/g'); do
                unset IFS

                opt_prefix="${literal%%=*}="
                literal="${literal#*=}"

                # Force secret backend
                if [ "${literal#*!}" != "${literal}" ]; then
                    if is_secret_backend "${literal%%\!*}"; then
                        load_secret_backend "${literal%%\!*}"
                        literal="${literal#*!}"
                    else
                        load_secret_backend "${DEFAULT_SECRET_BACKEND}"
                    fi
                else
                    load_secret_backend "${DEFAULT_SECRET_BACKEND}"
                fi

                if ! decrypted_literal=$(backend_decrypt_literal "${literal}"); then
                    fatal 'Unable to decrypt literal value %s' "${literal}"
                fi

                if [ "${decrypted_literal}" = "${literal}" ]; then
                    decrypted_literals="${decrypted_literals}${opt_prefix}${decrypted_literal},"
                else
                    decrypted_literals="${decrypted_literals}${opt_prefix}$(printf '%s' "${decrypted_literal}" | sed -e 's/\\/\\\\/g' | sed -e 's/,/\\,/g'),"
                fi
            done

            set -- "$@" "${decrypted_literals%*,}"
            ;;
        -f | --values | --values=?* | --set-file | --set-file=?*)
            _1="${1}"

            case "${_1}" in
            --values=* | --set-file=*)
                files="${_1#*=}"

                set -- "$@" "${_1%%=*}"
                ;;
            *)
                files="${2}"

                set -- "$@" "$1"
                shift
                j=$((j + 1))
                ;;
            esac

            decrypted_files=""

            IFS='
'

            for file in $(printf '%s' "${files}" | sed -E 's/([^\\]),/\1\n/g'); do
                unset IFS

                case "$_1" in
                -f | --values | --values=?*)
                    double_escape_need=0
                    sops_type="yaml"
                    opt_prefix=""
                    ;;
                --set-file | --set-file=?*)
                    double_escape_need=1
                    sops_type="auto"
                    opt_prefix="${file%%=*}="
                    file="${file#*=}"
                    ;;
                esac

                # Ignore error on files beginning with ?
                if [ "${file##\?}" != "${file}" ]; then
                    file="${file##\?}"
                    IGNORE_MISSING_VALUES=true
                fi

                # Force secret backend
                if [ "${file#*!}" != "${file}" ]; then
                    if is_secret_backend "${file%%\!*}"; then
                        load_secret_backend "${file%%\!*}"
                        file="${file#*!}"
                    else
                        load_secret_backend "${DEFAULT_SECRET_BACKEND}"
                    fi
                else
                    load_secret_backend "${DEFAULT_SECRET_BACKEND}"
                fi

                if ! real_file=$(_file_get "${file}"); then
                    if [ "${IGNORE_MISSING_VALUES}" = "true" ]; then
                        real_file="$(_mktemp)"
                    else
                        fatal 'File does not exist: %s' "${file}"
                    fi
                fi

                file_dec="$(_file_dec_name "${real_file}")"
                if [ -f "${file_dec}" ]; then
                    decrypted_files="${decrypted_files}${opt_prefix}$(_helm_winpath "${file_dec}" "${double_escape_need}"),"

                    if [ "${QUIET}" = "false" ]; then
                        log 'Decrypt skipped: %s' "${file}"
                    fi
                else
                    if decrypt_helper "${real_file}" "${sops_type}"; then
                        printf '%s\0' "${file_dec}" >>"${decrypted_file_list}"

                        if [ "${QUIET}" = "false" ]; then
                            log 'Decrypt: %s' "${file}"
                        fi

                        decrypted_files="${decrypted_files}${opt_prefix}$(_helm_winpath "${file_dec}" "${double_escape_need}"),"
                    else
                        decrypted_files="${decrypted_files}${opt_prefix}$(_helm_winpath "${real_file}" "${double_escape_need}"),"
                    fi
                fi
            done

            set -- "$@" "${decrypted_files%*,}"

            ;;
        *)
            if [ -d "$1" ] || [ -f "$1" ]; then
                set -- "$@" "$(_helm_winpath "${1}")"
            else
                set -- "$@" "$1"
            fi
            ;;
        esac

        shift
        j=$((j + 1))
    done

    if [ "${EVALUATE_TEMPLATES}" = "true" ]; then
        set -- "$@" "--post-renderer" "${HELM_BIN}"

        if [ "${HELM_DEBUG:-}" = "1" ] || [ "${HELM_DEBUG:-}" = "true" ] || [ -n "${HELM_SECRETS_DEBUG+x}" ]; then
            set -- "$@" "--post-renderer-args" "--debug"
        fi

        set -- "$@" "--post-renderer-args" "secrets"
        set -- "$@" "--post-renderer-args" "--backend" "--post-renderer-args" "${SECRET_BACKEND}"
        if [ "${SECRET_BACKEND_ARGS}" != "" ]; then
            set -- "$@" "--post-renderer-args" "--backend-args" "--post-renderer-args" "${SECRET_BACKEND_ARGS}"
        fi
        if [ "${EVALUATE_TEMPLATES_DECODE_SECRETS}" = "true" ]; then
            set -- "$@" "--post-renderer-args" "--evaluate-templates-decode-secrets"
        fi
        set -- "$@" "--post-renderer-args" "post-renderer"
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
