#!/usr/bin/env bash

set -ueo pipefail

usage() {
cat << EOF
GnuPG secrets encryption in Helm Charts

This plugin provides ability to encrypt/decrypt secrets files
to store in less secure places, before they are installed using
Helm.

To decrypt/encrypt/edit you need to initialize/first encrypt secrets with sops - https://github.com/mozilla/sops

Available Commands:
  enc    	Encrypt chart secrets file
  dec    	Decrypt chart secrets file
  clean         Clean all Decrypted files in specified directory
  view   	Print chart secrets decrypted
  edit   	Edit chart secrets and encrypt at the end

EOF
}

edit_usage() {
cat << EOF
Edit encrypted secrets

Decrypt encrypted file, edit and then encrypt

You can use plain sops to edit - https://github.com/mozilla/sops

Example:
  $ helm secrets edit <SECRET_FILE_PATH>
  or $ sops <SECRET_FILE_PATH>
  $ git add <SECRET_FILE_PATH>
  $ git commit
  $ git push

EOF
}

enc_usage() {
cat << EOF
Encrypt secrets

It uses your gpg credentials to encrypt .yaml file.

You can use plain sops to encrypt - https://github.com/mozilla/sops

Example:
  $ helm secrets enc <SECRET_FILE_PATH>
  $ git add <SECRET_FILE_PATH>
  $ git commit
  $ git push

EOF
}

dec_usage() {
cat << EOF
Decrypt secrets

It uses your gpg credentials to decrypt previously encrypted .yaml file.
Produces .yaml.dec file.

You can use plain sops to decrypt specific files - https://github.com/mozilla/sops

Example:
  $ helm secrets dec <SECRET_FILE_PATH>

Typical usage:
  $ helm secrets dec secrets/myproject/secrets.yaml
  $ vim secrets/myproject/secrets.yaml.dec

EOF
}

clean_usage() {
cat << EOF
Clean all decrypted files if any exist

It cleans all decrypted *.yaml.dec files in the specified directory
(recursively) if they exist

Example:
  $ helm secrets clean <dir with secrets>

EOF
}

view_usage() {
cat << EOF
View specified secrets.yaml file

Example:
  $ helm secrets view <SECRET_FILE_PATH>

Typical usage:
  $ helm secrets view secrets/myproject/nginx/secrets.yaml | grep basic_auth

EOF
}

is_help() {
  case "$1" in
  "-h"|"--help"|"help")
    return 0
    ;;
  *)
    return 1
    ;;
esac
}

sops_config() {
  #HELM_HOME=$(helm home)
  DEC_SUFFIX=".dec.yaml"
  SOPS_CONF_FILE=".sops.yaml"
}

get_md5() {
  # OS X
  if [[ -x $(which md5) ]]; then
    md5 "$1"
  # Linux
  elif [[ -x $(which m5sum) ]]; then
    md5sum "$1"
  else
    echo "Can't find md5 (OS X) or md5sum (Linux) command!"
    exit 1
  fi
}

encrypt_helper() {
    local dir=$(dirname "$1")
    local yml=$(basename "$1")
    cd "$dir"
    [[ -e "$yml" ]] || (echo "File not exist" && exit 1)
    sops_config
    local ymldec=$(sed -e "s/\\.yaml$/${DEC_SUFFIX}/" <<<"$yml")
    if [[ ! -e $ymldec ]]
    then
	ymldec="$yml"
    fi
  
    if [ "$(grep -C10000 'sops:' "$ymldec" | grep -c 'version:')" -gt 0 ];
    then
	echo "Already Encrypted."
	return
    fi
    if [[ $yml == $ymldec ]]
    then
	sops -e -i "$yml"
	echo "Encrypted $yml"
    else
	sops -e "$ymldec" > "$yml"
	echo "Encrypted $ymldec to $yml"
    fi
}

enc() {
  if is_help "$1" ; then
    enc_usage
    return
  fi
  yml="$1"
  if [[ ! -f "$yml" ]]; then
    echo "$yml doesn't exist."
  else
    echo "Encrypting $yml"
    encrypt_helper "$yml"
  fi
}

decrypt_helper() {
  local yml="$1"
  [[ -e "$yml" ]] || (echo "File not exist" && exit 1)
  sops_config
  local ymldec=$(sed -e "s/\\.yaml$/${DEC_SUFFIX}/" <<<"$yml")
  sops -d "$yml" > "$ymldec"
}

dec() {
  if is_help "$1" ; then
    dec_usage
    return
  fi
  yml="$1"
  if [[ ! -f "$yml" ]]; then
    echo "$yml doesn't exist."
  else
    echo "Decrypting $yml"
    decrypt_helper "$yml"
  fi
}

exec_edit()
{
    local file="$1"
    exec sops "${file}" < /dev/tty
}

clean() {
  if is_help "$1" ; then
    clean_usage
    return
  fi
  sops_config
  local basedir="$1"
  while read dec_file;
  do
  if [ -f "${dec_file}" ];
  then
     rm -v "${dec_file}"
  else
     echo "Nothing to Clean"
  fi
  done < <(find "${basedir}" -type f -name "*${DEC_SUFFIX}" )
}

view_helper() {
  local yml="$1"
  [[ -e "$yml" ]] || (echo "File not exist" && exit 1)
  sops_config
  sops -d "$yml"
}

edit_helper() {
  local yml="$1"
  [[ -e "$yml" ]] || (echo "File not exist" && exit 1)
  sops_config
  exec_edit "$yml"
}

view() {
  if is_help "$1" ; then
    view_usage
    return
  fi
  local yml="$1"
  view_helper "$yml"
}

edit() {
  local yml="$1"
  edit_helper "$yml"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

case "${1:-"help"}" in
  "enc"):
    if [[ $# -lt 2 ]]; then
      enc_usage
      echo "Error: Chart package required."
      exit 1
    fi
    enc "$2"
    shift
    ;;
  "dec"):
    if [[ $# -lt 2 ]]; then
      dec_usage
      echo "Error: Chart package required."
      exit 1
    fi
    dec "$2"
    ;;
  "clean"):
    if [[ $# -lt 2 ]]; then
      clean_usage
      echo "Error: Chart package required."
      exit 1
    fi
    clean "$2"
    ;;
  "view"):
    if [[ $# -lt 2 ]]; then
      view_usage
      echo "Error: Chart package required."
      exit 1
    fi
    view "$2"
    ;;
  "edit"):
    if [[ $# -lt 2 ]]; then
      edit_usage
      echo "Error: Chart package required."
      exit 1
    fi
    edit "$2"
    shift
    ;;
  "--help"|"help"|"-h")
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac

exit 0
