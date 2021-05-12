#!/bin/bash
source script/common/utils/common.sh

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

function start_dory {
  message 'Starting dory...'
  if dory status | grep -q 'not running'; then
    confirm_command 'dory up'
  elif ! dory status; then
    message "Something went wrong with dory! Exiting script."
    exit 1
  else
    message 'Looks like dory is already running. Moving on...'
  fi
}
