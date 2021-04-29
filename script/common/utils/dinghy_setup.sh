#!/bin/bash
source script/common/utils/common.sh

# Defaults
DINGHY_MEMORY='8192'
DINGHY_CPUS='4'
DINGHY_DISK='150'

function create_dinghy_vm {
  if ! dinghy status | grep -q 'not created'; then
    # make sure DOCKER_MACHINE_NAME is set
    eval "$(dinghy env)"
    existing_memory="$(docker-machine inspect --format "{{.Driver.Memory}}" "${DOCKER_MACHINE_NAME}")"
    if [[ "$existing_memory" -lt "$DINGHY_MEMORY" ]]; then
      echo "
  Canvas requires at least 8GB of memory dedicated to the VM. Please recreate
  your VM with a memory value of at least ${DINGHY_MEMORY}. For Example:

      $ dinghy create --memory ${DINGHY_MEMORY}"
      exit 1
    else
      message "Using existing dinghy VM..."
      return 0
    fi
  fi

  prompt 'OK to create a dinghy VM? [y/n]' confirm
  [[ ${confirm:-n} == 'y' ]] || return 1

  if ! installed VBoxManage; then
    message 'Please install VirtualBox first!'
    return 1
  fi

  prompt "How much memory should I allocate to the VM (in MB)? [$DINGHY_MEMORY]" memory
  prompt "How many CPUs should I allocate to the VM? [$DINGHY_CPUS]" cpus
  prompt "How big should the VM's disk be (in GB)? [$DINGHY_DISK]" disk

  message "OK let's do this."
  message "Creating dinghy machine..."
  _canvas_lms_track_with_log dinghy create \
    --provider=virtualbox \
    --memory "${memory:-$DINGHY_MEMORY}" \
    --cpus "${cpus:-$DINGHY_CPUS}" \
    --disk "${disk:-$DINGHY_DISK}000"
}

function start_dinghy_vm {
  if dinghy status | grep -q 'stopped'; then
    message "Starting dinghy VM..."
    _canvas_lms_track_with_log dinghy up
  else
    message 'Looks like the dinghy VM is already running. Moving on...'
  fi
  eval "$(dinghy env)"
}

function setup_dinghy_proxy {
  if [[ "$(docker ps -aq --filter ancestor=codekitchen/dinghy-http-proxy)" == "" ]]; then
    docker run -d --restart=always \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v ~/.dinghy/certs:/etc/nginx/certs \
    -p 80:80 -p 443:443 -p 19322:19322/udp \
    -e DNS_IP=127.0.0.1 -e CONTAINER_NAME=http-proxy \
    --name http-proxy \
    codekitchen/dinghy-http-proxy

    echo 'nameserver 127.0.0.1' | sudo tee /etc/resolver/docker > /dev/null
    echo 'port 19322' | sudo tee -a /etc/resolver/docker > /dev/null
  fi
}
