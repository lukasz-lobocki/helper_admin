#!/bin/bash

#  █████  ██████  ██████  ███████ ███    ██ ██████      ██   ██ ██   ██ ██   ██ ███████ ██    ██ ███    ███
# ██   ██ ██   ██ ██   ██ ██      ████   ██ ██   ██      ██ ██   ██ ██  ██   ██ ██      ██    ██ ████  ████
# ███████ ██████  ██████  █████   ██ ██  ██ ██   ██       ███     ███   ███████ ███████ ██    ██ ██ ████ ██
# ██   ██ ██      ██      ██      ██  ██ ██ ██   ██      ██ ██   ██ ██  ██   ██      ██ ██    ██ ██  ██  ██
# ██   ██ ██      ██      ███████ ██   ████ ██████      ██   ██ ██   ██ ██   ██ ███████  ██████  ██      ██

# Recursively adds missing xxhsum hashes from PATH to --xxhsum-filepath.

set -uo pipefail

function parse_params () {

  ! getopt --test > /dev/null
  if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
      printf 'I am sorry, `getopt --test` failed in this environment.\n' \
        1>&2
      exit 1
  fi

  OPTIONS=x:,h,v
  LONGOPTS=xxhsum-filepath:,help,verbose

  ! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
  if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
  fi

  eval set -- "$PARSED"

  while true; do
    case "$1" in
      -x|--xxhsum-filepath)
        xxhsum_file="${2}"
        shift 2
        ;;
      -v|--verbose)
        verbose="y"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        printf "Programming error\n" \
          1>&2
        exit 3
        ;;
    esac
  done

  # handle mandatory arguments
  if [[ $# -ne 1 ]]; then
    printf "%s: PATH parameter is required\n" \
      "$(basename "${0}")" \
      1>&2
    exit 4
  fi

  if [[ ! -d "${1}" ]]; then
    printf "%s: \${1}=PATH %s does not exist (-d)\n" \
      "$(basename "${0}")" \
      "${1}" \
      1>&2
    exit 5
  elif [[ ${verbose} == "y" ]]; then
    printf "%s: \${1}=PATH %s exists (+d)\n" \
      "$(basename "${0}")" \
      "${1}" \
      1>&2
  fi

  if [[ ! -r "${1}" ]]; then
    printf "%s: \${1}=PATH %s is not readable (-r)\n" \
      "$(basename "${0}")" \
      "${1}" \
      1>&2
    exit 5
  elif [[ ${verbose} == "y" ]]; then
    printf "%s: \${1}=PATH %s is readable (+r)\n" \
      "$(basename "${0}")" \
      "${1}" \
      1>&2
  fi

  if [[ ! -x "${1}" ]]; then
    printf "%s: \${1}=PATH %s is not browsable/executable (-x)\n" \
      "$(basename "${0}")" \
      "${1}" \
      1>&2
    exit 5
  elif [[ ${verbose} == "y" ]]; then
    printf "%s: \${1}=PATH %s is browsable/executable (+x)\n" \
      "$(basename "${0}")" \
      "${1}" \
      1>&2
  fi

  search_path="${1}"

  # handle optional parameters
  if [[ "${xxhsum_file}" == "" ]]; then
    xxhsum_file=$(realpath --canonicalize-missing --strip "${search_path}").xxhsum
    if [[ ${verbose} == "y" ]]; then
      printf "%s: --xxhsum-filepath defaulted to %s\n" \
        "$(basename "${0}")" \
        "${xxhsum_file}" \
        1>&2
    fi
  fi

  if [[ ! -f "${xxhsum_file}" ]]; then
    printf "%s: Creating --xxhsum-filepath=%s\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
    touch "${xxhsum_file}"
  elif [[ ${verbose} == "y" ]]; then
    printf "%s: --xxhsum-filepath=%s exists (+f)\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
  fi

  if [[ ! -r "${xxhsum_file}" ]]; then
    printf "%s: --xxhsum-filepath=%s is not readable (-r)\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
    exit 5
  elif [[ ${verbose} == "y" ]]; then
    printf "%s: --xxhsum-filepath=%s is readable (+r)\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
  fi

  if [[ ! -w "${xxhsum_file}" ]]; then
    printf "%s: --xxhsum-filepath=%s is not writable (-w)\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
    exit 5
  elif [[ ${verbose} == "y" ]]; then
    printf "%s: --xxhsum-filepath=%s is writable (+w)\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
  fi
}

function usage()
{
   cat << HEREDOC

   Usage: $(basename ${0}) [--xxhsum-filepath FILEPATH] [--verbose] [--help] PATH

   Recursively adds missing xxhsum hashes from PATH to --xxhsum-filepath.

   arguments:
     PATH                     PATH to analyze. Must exist and be readable (+r) and browsable/executable (+x).
     -x, --xxhsum-filepath    FILEPATH to file to append to. Defaults to PATH\..\DIRNAME.xxhsum. Must be readable (+r)
                              and writable (+w).
     -v, --verbose            increase the verbosity of the bash script.
     -h, --help               show this help message and exit.

HEREDOC
}


function load_xxhsum_file () {
  local key
  local value

  # providing no-split Internal Field Separator
  while IFS= read -r line; do
    # first word
    value="${line%% *}"
    # rest of line
    key="${line#* }"

    # skip comments
    if [[ ${value:0:1} == "#" ]]; then
      continue
    fi

    # remove a leading asterisk from the key (filename)
    if [[ ${key:0:1} == "*" ]]; then
      key="${key:1}"
    fi

    dict["${key}"]="${value}"
  done \
    < "${xxhsum_file}"

  if [[ ${verbose} == "y" ]]; then
    printf "%s: LOADED... %s\n" \
      "$(basename "${0}")" \
      "${xxhsum_file}" \
      1>&2
  fi
}


function dump_xxhsum_dict () {
  local key  

  printf "%s: DUMPING... \${!dict}\n" \
    "$(basename "${0}")" \
    1>&2

  for key in "${!dict[@]}"; do
    printf "%s: %s {%s}\n" \
      "$(basename "${0}")" \
      "${key}" "${dict[${key}]}" \
      1>&2
  done
}


function search_dir () {
  local file
  declare -i counter
  counter=0

  if [[ ${verbose} == "y" ]]; then
    printf "%s: SEARCHING... %s\n" \
      "$(basename "${0}")" \
      "${search_path}" \
      1>&2
  fi

  pushd "${search_path}/.." >/dev/null

  while read -r -d $'\0' file; do
    if [[ ${dict["${file}"]+_} ]]; then
      if [[ ${verbose} == "y" ]]; then
        printf "%s: %s found\n" \
          "$(basename "${0}")" \
          "${file}" \
          1>&2
      fi
    else
      xxhsum "${file}" | tee -a "${xxhsum_file}"
      counter=$((counter+1))
    fi
  done < \
      <(find "$(basename "${search_path}")" -type f -print0)

  printf "%s: %d xxhsum hashes added\n" \
    "$(basename "${0}")" \
    $counter \
    1>&2

  popd >/dev/null
}


function main () {

  search_path=""
  xxhsum_file=""
  declare -A dict
  verbose="n"

  parse_params "$@"
  load_xxhsum_file
  if [[ ${verbose} == "y" ]]; then
    dump_xxhsum_dict
  fi
  search_dir

  unset dict
}

main "$@"
