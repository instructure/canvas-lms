#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

export ERROR_CONTEXT_BASE_PATH="`pwd`/log/spec_failures/Initial"

success_status=0
webdriver_crash_status=98
test_failure_status=99

max_failures=${MAX_FAIL:=200} # TODO: need to get env variable setup, MAX number of failures before quit
rerun_number=0
runs_remaining=$((1+${RERUNS_RETRY:=2}))

rerun_line="adding spec to rerun (\./[^ ]+)"
exempt_from_rerun_threshold_line="exceptions are exempt from rerun thresholds"
failed_relevant_spec_line="not adding modified spec to rerun (\./.*)"

pipe=/tmp/rspec-queue-pipe
rm -f $pipe
mkfifo $pipe

echo "STARTING"
while true; do
  last_status=0
  new_spec_list=()
  exempt_spec_list=()
  failed_relevant_spec_list=()

  if [[ $reruns_started ]]; then
    echo "FAILED SPECS"
    docker-compose exec -T web bash -c "grep -hnr 'failed' /usr/src/app/tmp/rspec"
    echo "CAT THE ENTIRE FILE"
    docker-compose exec -T web bash -c "cat /usr/src/app/tmp/rspec"
    if [ $1 ] && [ $1 = 'performance' ]; then
      command="docker-compose exec -T web bundle exec rspec --options spec/spec.opts spec/selenium/performance/ --only-failures --failure-exit-code 99";
    else
      command="build/new-jenkins/rspec-tests.sh only-failures";
    fi
  else
    if [ $1 ] && [ $1 = 'performance' ]; then
      command="docker-compose exec -T web bundle exec rspec --options spec/spec.opts spec/selenium/performance/ --failure-exit-code 99"
    else
      command="build/new-jenkins/rspec-tests.sh"
    fi
  fi
  echo "Running $command"
  $command >$pipe 2>&1 &
  command_pid=$!

  while IFS= read line; do
    echo "$line" || exit 2
    if [[ $line =~ $rerun_line ]]; then
      new_spec="${BASH_REMATCH[1]}"
      new_spec_list+=("$new_spec")
      if [[ $line =~ $exempt_from_rerun_threshold_line ]]; then
        exempt_spec_list+=("$new_spec")
      fi
    elif [[ $line =~ $failed_relevant_spec_line ]]; then
      failed_relevant_spec_list+=("${BASH_REMATCH[1]}")
    fi
  done <$pipe
  wait $command_pid || last_status=$?
  [[ ! $reruns_started ]] && echo "FINISHED"

  # TODO: can probably get rid of
  # between test-queue and the formatter we get double output; uniq them
  new_spec_list=($(echo "${new_spec_list[@]}"|tr ' ' '\n'|sort -u|tr '\n' ' '))
  failed_relevant_spec_list=($(echo "${failed_relevant_spec_list[@]}"|tr ' ' '\n'|sort -u|tr '\n' ' '))
  failures_exempt_from_rerun_threshold=$(echo "${exempt_spec_list[@]}"|tr ' ' '\n'|grep .|sort -u|wc -l)

  echo "last status: $last_status"
  [[ $last_status == $success_status ]] && break

  if [[ $last_status != $success_status && $last_status != $webdriver_crash_status && $last_status != $test_failure_status ]]; then
    echo "unexpected exit code $last_status! perhaps the code is horribly broken :("
    break
  fi

  if [[ $last_status == $webdriver_crash_status ]]; then
    echo "a webdriver worker crashed; retrigger your build"
    break
  fi

  if [[ $last_status == $test_failure_status ]]; then
    rerun_number=$((rerun_number+1))
    runs_remaining=$((runs_remaining-1))
    num_failures=${#new_spec_list[@]}

    [[ $runs_remaining == 0 ]] && { echo "reruns failed $num_failures failure(s)"; break; }
    export ERROR_CONTEXT_BASE_PATH="`pwd`/log/spec_failures/Rerun $rerun_number"

    failures_towards_rerun_threshold=$((num_failures-failures_exempt_from_rerun_threshold))
    if [[ failures_towards_rerun_threshold -gt $max_failures ]]; then
      echo "too many failures (got: $num_failures, exempt from threshold: $failures_exempt_from_rerun_threshold, max: $max_failures), build not eligible for reruns" || :
      break
    fi

    failed_relevant_spec_list_length=${#failed_relevant_spec_list[@]}
    if [[ "$DONT_RERUN_RELEVANT_SPECS" == "1" && failed_relevant_spec_list_length -gt 0 ]]; then
      echo "specs relevant to this commit failed: ${failed_relevant_spec_list[@]}, build not eligible for reruns" || :
      break
    fi

    if [[ $num_failures == 0 ]]; then
      echo "nothing to re-run! perhaps the code is horribly broken? :("
      break
    fi

    echo -e "failed, re-trying $num_failures failure(s) ($failures_towards_rerun_threshold against threshold), $runs_remaining attempt(s) left\n\n\n"

    if [[ ! $reruns_started ]]; then
      reruns_started=1
      echo "RERUN STARTING"
    fi
  fi
done

[[ $reruns_started ]] && echo " FINISHED"
echo "rspec-queue-with-retries exiting with $last_status"
exit $last_status
