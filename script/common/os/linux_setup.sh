#!/bin/bash
source script/common/utils/common.sh
dependencies='docker,docker-compose 1.20.0'

function check_for_dory {
  if ! installed dory; then
    printf "\tCanvas recommends using dory for a reverse proxy allowing you to
\taccess canvas at http://canvas.docker. Detailed instructions
\tare available at https://github.com/FreedomBen/dory.
\tIf you want to install it, run 'gem install dory' then rerun this script.\n"
    prompt 'Would you like to skip dory? [y/n]' skip_dory
    [[ ${skip_dory:-n} != 'y' ]] || return 0
    echo 'Install dory then rerun this script.'
    exit 1
  fi
}

function start_docker_daemon {
  eval "$service_manager docker status &> /dev/null" && return 0
  prompt 'The docker daemon is not running. Start it? [y/n]' confirm
  [[ ${confirm:-n} == 'y' ]] || return 1
  eval "$start_docker"
  sleep 1 # wait for docker daemon to start
}

function setup_docker_as_nonroot {
  docker ps &> /dev/null && return 0
  message 'Setting up docker for nonroot user...'
  if ! id -Gn "$USER" | grep -q '\bdocker\b'; then
    message "Adding $USER user to docker group..."
    confirm_command "sudo usermod -aG docker $USER" || true
  fi
  message 'We need to login again to apply that change.'
  confirm_command "exec sg docker -c $0"
}

function start_dory {
  message 'Starting dory...'
  if dory status | grep -q 'not running'; then
    confirm_command 'dory up'
  else
    message 'Looks like dory is already running. Moving on...'
  fi
}

if installed service; then
  service_manager='service'
  start_docker="sudo service docker start"
elif installed systemctl; then
  service_manager='systemctl'
  start_docker="sudo systemctl start docker"
else
  echo "Unable to find 'service' or 'systemctl' installed."
  exit 1
fi

message "It looks like you're using Linux. Let's set that up."
check_dependencies
check_for_dory
start_docker_daemon
setup_docker_as_nonroot
[[ ${skip_dory:-n} == 'y' ]] || start_dory
