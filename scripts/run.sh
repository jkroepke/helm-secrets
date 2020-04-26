#!/usr/bin/env sh

set -eu

# The suffix to use for decrypted files. The default can be overridden using
# the HELM_SECRETS_DEC_SUFFIX environment variable.
DEC_SUFFIX="${HELM_SECRETS_DEC_SUFFIX:-.yaml.dec}"
DEC_DIR="${HELM_SECRETS_DEC_DIR:-}"

# Make sure HELM_BIN is set (normally by the helm command)
HELM_BIN="${HELM_BIN:-helm}"

usage() {
	cat <<EOF
GnuPG secrets encryption in Helm Charts

This plugin provides ability to encrypt/decrypt secrets files
to store in less secure places, before they are installed using
Helm.

To decrypt/encrypt/edit you need to initialize/first encrypt secrets with
sops - https://github.com/mozilla/sops

Available Commands:
  enc     Encrypt secrets file
  dec     Decrypt secrets file
  view    Print secrets decrypted
  edit    Edit secrets file and encrypt afterwards
  clean   Remove all decrypted files in specified directory (recursively)
  <cmd>   wrapper that decrypts secrets[.*].yaml files before running helm <cmd>

EOF
}

enc_usage() {
	cat <<EOF
Encrypt secrets

It uses your gpg credentials to encrypt .yaml file. If the file is already
encrypted, look for a decrypted ${DEC_SUFFIX} file and encrypt that to .yaml.
This allows you to first decrypt the file, edit it, then encrypt it again.

You can use plain sops to encrypt - https://github.com/mozilla/sops

Example:
  $ ${HELM_BIN} secrets enc <SECRET_FILE_PATH>
  $ git add <SECRET_FILE_PATH>
  $ git commit
  $ git push

EOF
}

dec_usage() {
	cat <<EOF
Decrypt secrets

It uses your gpg credentials to decrypt previously encrypted .yaml file.
Produces ${DEC_SUFFIX} file.

You can use plain sops to decrypt specific files - https://github.com/mozilla/sops

Example:
  $ ${HELM_BIN} secrets dec <SECRET_FILE_PATH>

Typical usage:
  $ ${HELM_BIN} secrets dec secrets/myproject/secrets.yaml
  $ vim secrets/myproject/secrets.yaml.dec

EOF
}

view_usage() {
	cat <<EOF
View specified secrets[.*].yaml file

Example:
  $ ${HELM_BIN} secrets view <SECRET_FILE_PATH>

Typical usage:
  $ ${HELM_BIN} secrets view secrets/myproject/nginx/secrets.yaml | grep basic_auth

EOF
}

edit_usage() {
	cat <<EOF
Edit encrypted secrets

Decrypt encrypted file, edit and then encrypt

You can use plain sops to edit - https://github.com/mozilla/sops

Example:
  $ ${HELM_BIN} secrets edit <SECRET_FILE_PATH>
  or $ sops <SECRET_FILE_PATH>
  $ git add <SECRET_FILE_PATH>
  $ git commit
  $ git push

EOF
}

clean_usage() {
	cat <<EOF
Clean all decrypted files if any exist

It removes all decrypted ${DEC_SUFFIX} files in the specified directory
(recursively) if they exist.

Example:
  $ ${HELM_BIN} secrets clean <dir with secrets>

EOF
}

helm_command_usage() {
	cat <<EOF
helm secrets $1 [ --quiet | -q ]

This is a wrapper for "helm [command]". It will detect -f and
--values options, and decrypt any secrets*.yaml files before running "helm
[command]".

Example:
  $ ${HELM_BIN} secrets upgrade <HELM UPGRADE OPTIONS>
  $ ${HELM_BIN} secrets lint <HELM LINT OPTIONS>

Typical usage:
  $ ${HELM_BIN} secrets upgrade i1 stable/nginx-ingress -f values.test.yaml -f secrets.test.yaml
  $ ${HELM_BIN} secrets lint ./my-chart -f values.test.yaml -f secrets.test.yaml

EOF
}

is_help() {
	case "$1" in
	-h | --help | help)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

is_file_encrypted() {
	grep -q 'sops:' "${1}" && grep -q 'version:' "${1}"
}

file_dec_name() {
	if [ "${DEC_DIR}" != "" ]; then
		echo "${DEC_DIR}/$(basename "${1}" ".yaml")${DEC_SUFFIX}"
	else
		echo "$(dirname "${1}")/$(basename "${1}" ".yaml")${DEC_SUFFIX}"
	fi
}

encrypt_helper() {
	dir=$(dirname "$1")
	file=$(basename "$1")

	cd "$dir"

	if [ ! -f "${file}" ]; then
		echo "File does not exist: ${dir}/${file}"
		exit 1
	fi

	file_dec="$(file_dec_name "${file}")"

	if [ ! -f "${file_dec}" ]; then
		file_dec="${file}"
	fi

	if is_file_encrypted "${file_dec}"; then
		echo "Already encrypted: ${file_dec}"
		exit 1
	fi

	if [ "${file}" = "${file_dec}" ]; then
		sops --encrypt --input-type yaml --output-type yaml --in-place "${file}"
		echo "Encrypted ${file}"
	else
		sops --encrypt --input-type yaml --output-type yaml "${file_dec}" >"${file}"
		echo "Encrypted ${file_dec} to ${file}"
	fi
}

enc() {
	if is_help "$1"; then
		enc_usage
		return
	fi

	file="$1"

	if [ ! -f "${file}" ]; then
		echo "File does not exist: ${file}"
		exit 1
	else
		echo "Encrypting ${file}"
		encrypt_helper "${file}"
	fi
}

decrypt_helper() {
	file="${1}"

	if [ ! -f "$file" ]; then
		echo "File does not exist: ${file}"
		exit 1
	fi

	if ! is_file_encrypted "${file}"; then
		return 1
	fi

	file_dec="$(file_dec_name "${file}")"

	if ! sops --decrypt --input-type yaml --output-type yaml --output "${file_dec}" "${file}"; then
		echo "Error while decrypting file: ${file}"
		exit 1
	fi

	return 0
}

dec() {
	if is_help "$1"; then
		dec_usage
		return
	fi

	file="$1"

	if [ ! -f "${file}" ]; then
		echo "File does not exist: ${file}"
		exit 1
	else
		echo "Decrypting ${file}"
		decrypt_helper "${file}"
	fi
}

view_helper() {
	file="$1"

	if [ ! -f "${file}" ]; then
		echo "File does not exist: ${file}"
		exit 1
	fi

	exec sops --decrypt --input-type yaml --output-type yaml "${file}"
}

view() {
	if is_help "$1"; then
		view_usage
		return
	fi

	view_helper "$1"
}

edit_helper() {
	file="$1"

	if [ ! -e "${file}" ]; then
		echo "File does not exist: ${file}"
		exit 1
	fi

	exec sops --input-type yaml --output-type yaml "${file}"
}

edit() {
	file="$1"
	edit_helper "${file}"
}

clean() {
	if is_help "$1"; then
		clean_usage
		return
	fi

	basedir="$1"

	if [ ! -d "${basedir}" ]; then
		echo "Directory does not exist: ${basedir}"
		exit 1
	fi

	find "$basedir" -type f -name "secrets*${DEC_SUFFIX}" -exec rm -v {} \;
}

helm_wrapper_cleanup() {
	if [ "${QUIET}" = "false" ]; then
		echo >/dev/stderr
		# shellcheck disable=SC2016
		xargs -0 -n1 sh -c 'rm -f "$1" && echo "[helm-secrets] Removed: $1"' sh >/dev/stderr <"${decrypted_files}"
	else
		xargs -0 rm -f >/dev/stderr <"${decrypted_files}"
	fi

	rm -f "${decrypted_files}"
}

helm_wrapper() {
	decrypted_files=$(mktemp)
	QUIET=false
	HELM_CMD_SET=false

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
		-f | --values)
			set -- "$@" "$1"

			file="${2}"
			if decrypt_helper "${file}"; then
				file_dec="$(file_dec_name "${file}")"
				set -- "$@" "$file_dec"
				printf '%s\0' "${file_dec}" >>"${decrypted_files}"

				if [ "${QUIET}" = "false" ]; then
					echo "[helm-secrets] Decrypt: ${file}" >/dev/stderr
				fi
			else
				set -- "$@" "$file"
			fi

			shift
			j=$((j + 1))
			;;
		-*)
			if [ "${HELM_CMD_SET}" = "false" ]; then
				case "$1" in
				-q | --quiet)
					QUIET=true
					;;
				*)
					set -- "$@" "$1"
					;;
				esac
			else
				set -- "$@" "$1"
			fi
			;;
		*)
			HELM_CMD_SET=true
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

case "${1:-}" in
enc)
	if [ $# -lt 2 ]; then
		enc_usage
		echo "Error: secrets file required."
		exit 1
	fi
	enc "$2"
	shift
	;;
dec)
	if [ $# -lt 2 ]; then
		dec_usage
		echo "Error: secrets file required."
		exit 1
	fi
	dec "$2"
	;;
view)
	if [ $# -lt 2 ]; then
		view_usage
		echo "Error: secrets file required."
		exit 1
	fi
	view "$2"
	;;
edit)
	if [ $# -lt 2 ]; then
		edit_usage
		echo "Error: secrets file required."
		exit 1
	fi
	edit "$2"
	shift
	;;
clean)
	if [ $# -lt 2 ]; then
		clean_usage
		echo "Error: Chart package required."
		exit 1
	fi
	clean "$2"
	;;
--help | -h | help)
	usage
	;;
"")
	usage
	exit 1
	;;
*)
	helm_command "$@"
	;;
esac

exit 0
