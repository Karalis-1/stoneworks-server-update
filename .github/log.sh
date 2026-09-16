#!/bin/bash

set -uo pipefail

function _log_exception() {
  (
    BASHLOG_FILE=0
    BASHLOG_JSON=0
    BASHLOG_SYSLOG=0

    log 'error' "Logging Exception: ${@}"
  )
}

function log() {
  local date_format="${BASHLOG_DATE_FORMAT:-+%F %T}"
  local date="$(date "${date_format}")"
  local date_s="$(date "+%s")"

  local file="${BASHLOG_FILE:-0}"
  local file_path="${BASHLOG_FILE_PATH:-/tmp/$(basename "${0}").log}"

  local json="${BASHLOG_JSON:-0}"
  local json_path="${BASHLOG_JSON_PATH:-/tmp/$(basename "${0}").log.json}"

  local syslog="${BASHLOG_SYSLOG:-0}"
  local tag="${BASHLOG_SYSLOG_TAG:-$(basename "${0}")}"
  local facility="${BASHLOG_SYSLOG_FACILITY:-local0}"
  local pid="${$}"

  local level="${1}"
  local upper="$(echo "${level}" | awk '{print toupper($0)}')"
  local debug_level="${DEBUG:-0}"

  shift 1

  local line="${@}"

  local -A severities
  severities['DEBUG']=7
  severities['INFO']=6
  severities['NOTICE']=5
  severities['WARN']=4
  severities['ERROR']=3
  severities['CRIT']=2
  severities['ALERT']=1
  severities['EMERG']=0

  local severity="${severities[${upper}]:-3}"

  if [ "${debug_level}" -gt 0 ] || [ "${severity}" -lt 7 ]; then
    if [ "${syslog}" -eq 1 ]; then
      local syslog_line="${upper}: ${line}"

      logger \
        --id="${pid}" \
        -t "${tag}" \
        -p "${facility}.${severity}" \
        "${syslog_line}" \
        || _log_exception "logger --id=\"${pid}\" -t \"${tag}\" -p \"${facility}.${severity}\" \"${syslog_line}\""
    fi

    if [ "${file}" -eq 1 ]; then
      local file_line="${date} [${upper}] ${line}"
      echo -e "${file_line}" >> "${file_path}" \
        || _log_exception "echo -e \"${file_line}\" >> \"${file_path}\""
    fi

    if [ "${json}" -eq 1 ]; then
      local json_line="$(printf '{"timestamp":"%s","level":"%s","message":"%s"}' "${date_s}" "${level}" "${line}")"
      echo -e "${json_line}" >> "${json_path}" \
        || _log_exception "echo -e \"${json_line}\" >> \"${json_path}\""
    fi
  fi

  local -A colours
  colours['DEBUG']='\033[34m'
  colours['INFO']='\033[32m'
  colours['NOTICE']=''
  colours['WARN']='\033[33m'
  colours['ERROR']='\033[31m'
  colours['CRIT']=''
  colours['ALERT']=''
  colours['EMERG']=''
  colours['DEFAULT']='\033[0m'

  local norm="${colours['DEFAULT']}"
  local colour="${colours[${upper}]:-\033[31m}"

  local std_line="${colour}${date} [${upper}] ${line}${norm}"

  case "${level}" in
    'info'|'warn')
      echo -e "${std_line}"
      ;;
    'debug')
      if [ "${debug_level}" -gt 0 ]; then
        echo -e "${std_line}"
      fi
      ;;
    'error')
      echo -e "${std_line}" >&2
      if [ "${debug_level}" -gt 0 ]; then
        echo -e "Here's a shell to debug with. 'exit 0' to continue. Other exit codes will abort. The parent shell will terminate."
        bash || exit "${?}"
      fi
      ;;
    *)
      log 'error' "Undefined log level trying to log: ${@}"
      ;;
  esac
}

declare prev_cmd="null"
declare this_cmd="null"
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG \
  && log debug 'DEBUG trap set' \
  || log error 'DEBUG trap failed to set'
