#!/bin/bash
source script/common.sh

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
  _canvas_lms_track dinghy create \
    --provider=virtualbox \
    --memory "${memory:-$DINGHY_MEMORY}" \
    --cpus "${cpus:-$DINGHY_CPUS}" \
    --disk "${disk:-$DINGHY_DISK}000"
}

function start_dinghy_vm {
  if dinghy status | grep -q 'stopped'; then
    _canvas_lms_track dinghy up
  else
    message 'Looks like the dinghy VM is already running. Moving on...'
  fi
  eval "$(dinghy env)"
}
