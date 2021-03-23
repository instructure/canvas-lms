#
# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

function _inst_spinner() {

  local SUCCESS="DONE"
  local FAILURE="FAIL"
  local RED='\e[31m'
  local GREEN='\e[32m'
  local YELLOW='\e[33m'
  local NC='\e[0m' # No Color
  local bold=$(tput bold)
  local normal=$(tput sgr0)

  case $1 in
    start)
      printf "\n${bold}> ${@:2}${normal}"
      if [[ ! -z ${LOG-} ]]; then
        echo "${@:2}" >> "$LOG"
      fi
      printf "\t"

      i=1
      sp='\|/-'
      delay=${SPINNER_DELAY:-0.15}

      while :
      do
        printf "\b${sp:i++%${#sp}:1}"
        sleep $delay
      done
      ;;
    stop)
      if [[ -z ${3:-} ]]; then
        # no pid to kill
        return
      fi

      kill $3 > /dev/null 2>&1

      printf "\b["
      if [[ $2 -eq 0 ]]; then
        printf "${GREEN}${SUCCESS}${NC}"
      elif [[ $2 -eq 130 ]]; then
        printf "${YELLOW}INTERRUPTED${NC}"
      else
        printf "${RED}${FAILURE}${NC}"
      fi
      printf "]\n"
      ;;
    *)
      echo "invalid argument, try {start/stop}"
      exit 1
      ;;
  esac
}

function start_spinner {
  _inst_spinner "start" "$1" &
  export _sp_pid=$!
  disown
}

function stop_spinner {
  exit_status=$?
  if [[ ! -z ${1-} ]]; then
    exit_status=$1
  fi
  _inst_spinner "stop" $exit_status ${_sp_pid:-}
  unset _sp_pid
}
