#!/bin/bash

set -eu

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
  dec-deps    	Decrypt chart's dependecies' secrets files
  view   	Print chart secrets decrypted
  edit   	Edit chart secrets and ecrypt at the end

EOF
}

edit_usage() {
cat << EOF
Edit encrypted Chart secrets.yaml

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
Encrypt Chart secrets.yaml

It uses your gpg credentials to encrypt secrets.yaml file
in your chart templates directory.

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
Decrypt Chart secrets.yaml

It uses your gpg credentials to decrypt previously encrypted secrets.yaml file
in your chart templates directory. Produce secrets.yaml.dec file which if exist
is used to encrypt to secrets.yaml.

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

It cleans all decrypted secrets.yaml.dec files in your chart
templates directory if they exist

Example:
  $ helm secrets clean <dir with secrets>

EOF
}

dec_deps_usage() {
cat << EOF
Decrypt secrets.yaml files in Chart's dependencies.

Example:
  $ helm secrets dec-deps <CHART>

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

vars_load() {
  export templates_dir="${chart}"
  if [[ -f "${templates_dir}/templates/secrets.yaml" ]]; then
    export yml="${templates_dir}/templates/secrets.yaml"
  elif [[ -f "${templates_dir}/secrets.yml" ]]; then
    echo "WARNING for ${chart}: secrets.yml should be renamed to secrets.yaml"
    export yml="${templates_dir}/secrets.yml"
  # load defined file in dir
  elif [[ -f "${templates_dir}" ]]; then
    export yml="${templates_dir}"
  fi
}

sops_config() {
  #HELM_HOME=$(helm home)
  DEC_SUFFIX=".dec"
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
  file "$yml" > /dev/null || (echo "File not exist" && exit 1)
  sops_config
  count_match=0
  matched_dir=""
  while read sops_config_path;
  do
    if [ "$(echo "$yml" | grep -F "$sops_config_path")" ];
         then
            matched_dir=$sops_config_path
            (( count_match++ ))
    fi
  done < <(find . -type f -name ".sops.yaml" -exec dirname {} \; | sed -e 's/\.\///g')
  SOPS_CONF_PATH="$matched_dir/${SOPS_CONF_FILE}"
  if [ -f "${SOPS_CONF_PATH}" ];
   then
       if [ "$(grep -C10000 'sops:' "$yml" | grep -c 'version:')" -gt 0 ];
       then
          echo "Already Encrypted."
          return
      fi
          sops --config "${SOPS_CONF_PATH}" -e -i "$yml"
          echo "Encrypted $yml"
          return
  fi
  if [ "$count_match" -eq 0 ];
   then
       echo "Could not encrypt $yml. No .sops.yaml config file found."
       exit 1
  fi
}

enc() {
  if is_help "$1" ; then
    enc_usage
    return
  fi
  chart=$1
  yml=""
  vars_load "$chart"
  echo "Encrypting $chart"
  encrypt_helper "$yml"
}

decrypt_helper() {
  file "$yml" > /dev/null || (echo "File not exist" && exit 1)
  sops_config
  sops -d "$yml" > "${yml}${DEC_SUFFIX}"
}

dec() {
  if is_help "$1" ; then
    dec_usage
    return
  fi
  chart=$1
  yml=""
  vars_load "$chart"
  if [[ -z "$yml" ]]; then
    echo "$chart doesn't have secrets.yaml file."
  else
    echo "Decrypting $chart"
    decrypt_helper "$yml"
  fi
}

dec_deps() {
  if is_help "$1" ; then
    dec_deps_usage
    return
  fi
  chart=$1
  chart_path="${chart%/*}"
  echo "Decrypting ${chart}'s dependencies."
  deps=$(helm dep list "$chart" | awk 'NR>=2 { print $1 }' | xargs)
  yml=""
  for dep in $deps
  do
    dec "${chart_path}/${dep}"
  done
}

clean() {
  if is_help "$1" ; then
    clean_usage
    return
  fi
  sops_config
  chart="$1"
  vars_load "$chart"
  echo "Decrypted secrets files clean"
  while read dec_file;
  do
  if [ -f "${dec_file}" ]; then
     rm -v  "${dec_file}"
  else
     echo "Nothing to Clean"
  fi
  done < <(find "$templates_dir" -type f -name "*.yaml${DEC_SUFFIX}" )
}

view_helper() {
  file "$yml" > /dev/null || (echo "File not exist" && exit 1)
  sops_config
  sops -d "$yml"
}

edit_helper() {
  file "$yml" > /dev/null || (echo "File not exist" && exit 1)
  sops_config
  sops "$(which "$yml")"
}

view() {
  if is_help "$1" ; then
    view_usage
    return
  fi
  chart=$1
  yml=""
  vars_load "$chart"
  view_helper
}

edit() {
  if ! type "vim" > /dev/null; then
    echo "Command like 'vim' must be installed to edit before re-encrypt"
    exit 1
  fi
  chart=$1
  vars_load "$chart"
  edit_helper
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
  "dec-deps"):
    if [[ $# -lt 2 ]]; then
      dec_deps_usage
      echo "Error: Chart package required."
      exit 1
    fi
    dec_deps "$2"
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
