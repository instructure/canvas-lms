#!/bin/bash
source script/common/utils/spinner.sh

function set_service_util {
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
