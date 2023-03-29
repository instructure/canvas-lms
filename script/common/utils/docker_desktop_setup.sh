#!/bin/bash
source script/common/utils/spinner.sh
source script/common/utils/logging.sh

function get_parent_pid {
  PID=${1:-$$}
  PARENT=$(ps -p "$PID" -o ppid=)

  # /sbin/init always has a PID of 1, so if you reach that, the current PID is
  # the top-level parent. Otherwise, keep looking.
  if [[ ${PARENT} -eq 1 ]] ; then
    echo "${PID}"
  else
    get_parent_pid "${PARENT}"
  fi
}

function bring_window_to_top {
  osascript<<EOF
  tell application "System Events"
    set processList to every process whose unix id is ${1}
    repeat with proc in processList
      set the frontmost of proc to true
    end repeat
  end tell
EOF
}

function check_docker_memory {
  docker_memory="$(docker info --format "{{.MemTotal}}")"
  if [[ "$docker_memory" -lt '8300000000' ]]; then
    echo_console_and_log "
  Canvas requires at least 8GB of memory dedicated to Docker Desktop. Please refer to
  https://docs.docker.com/desktop/settings/mac/#advanced for more info on increasing your memory."
    exit 1
  fi
}

function attempt_start_docker {
  start_spinner "Attempting to start Docker Desktop..."
  terminal_pid=$(get_parent_pid)
  open -a Docker && while ! docker system info > /dev/null 2>&1; do sleep 1; done
  bring_window_to_top "$terminal_pid"
  stop_spinner
}

function check_for_docker_desktop {
  if [[ -z $(mdfind kind:application Docker.app) ]]; then
    echo "  Docker Desktop is not installed!"
    echo "  Refer to https://docs.docker.com/docker-for-mac/install/ for help installing."
    echo "  Once Docker Desktop is installed rerun this script."
    exit 1
  fi
}
