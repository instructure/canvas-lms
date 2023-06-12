#!/bin/bash

# no `-o nounset` nor `-o pipefail`  because this legacy script
# has a lot of unset variables and needs to be addressed independently
set -o errexit -o errtrace -o xtrace

PROCESSES=$((${RSPEC_PROCESSES:=1}-1))
export ERROR_CONTEXT_BASE_PATH="/usr/src/app/log/spec_failures/Initial"

success_status=0
test_failure_status=1
rerun_number=1
runs_remaining=${RERUNS_RETRY:=2}

echo "STARTING"
while true; do
  last_statuses=()
  command_pids=()

  if [[ $reruns_started ]]; then
    if [ $1 ] && [ $1 = 'performance' ]; then
      commands+=("docker-compose exec -T canvas bundle exec rspec --options spec/spec.opts spec/selenium/performance/ --only-failures --failure-exit-code 99")
    fi
  else
    if [ $1 ] && [ $1 = 'performance' ]; then
      commands+=("docker-compose exec -T canvas bundle exec rspec --options spec/spec.opts spec/selenium/performance/ --failure-exit-code 99")
    fi
  fi

  for command in "${commands[@]}"; do
    ./build/new-jenkins/linters/run-and-collect-output.sh "$command" 2>&1 &
    command_pids[$!]=$command
  done

  for command_pid in "${!command_pids[@]}"; do
    wait $command_pid || last_statuses[$command_pid]=$?
  done

  exit_code=0
  commands=()
  for command_pid in ${!last_statuses[@]}; do
    last_status="${last_statuses[$command_pid]}"
    if [[ $last_status == $success_status ]]; then
      continue
    elif [[ $last_status == $test_failure_status ]]; then
      export ERROR_CONTEXT_BASE_PATH="/usr/src/app/log/spec_failures/Rerun_$rerun_number"

      if [[ $runs_remaining == 0 ]]; then
        exit_code=$last_status
        break 2
      fi

      reruns_started=1
      echo -e "RERUN STARTING: failed in running command: ${command_pids[$command_pid]}, $runs_remaining attempt(s) left\n\n\n"
      commands+=("${command_pids[$command_pid]} only-failures")
      exit_code=$last_status
    else
      echo "unexpected exit code $last_status! perhaps the code is horribly broken :("
      exit_code=$last_status
      break 2
    fi
  done

  [[ $exit_code == 0 ]] && break
  rerun_number=$((rerun_number+1))
  runs_remaining=$((runs_remaining-1))
done

echo "FINISHED: rspec-queue-with-retries exiting with $exit_code"
exit $exit_code
