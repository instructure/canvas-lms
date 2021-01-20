#!/bin/bash

# no `-o nounset` nor `-o pipefail`  because this legacy script
# has a lot of unset variables and needs to be addressed independently
set -o errexit -o errtrace -o xtrace

export ERROR_CONTEXT_BASE_PATH="/usr/src/app/log/spec_failures/Initial"

success_status=0
test_failure_status=1

runs_remaining=$((1+${RERUNS_RETRY:=2}))

echo "STARTING"
while true; do
  set +e
  if [[ $reruns_started ]]; then
    if [ $1 ] && [ $1 = 'performance' ]; then
      build/new-jenkins/rspec-with-wait.sh "docker-compose --project-name canvas-lms0 exec -T canvas bundle exec rspec --options spec/spec.opts spec/selenium/performance/ --only-failures --failure-exit-code 99"
    else
      build/new-jenkins/rspec-with-wait.sh "build/new-jenkins/rspec-tests.sh only-failures"
    fi
  else
    if [ $1 ] && [ $1 = 'performance' ]; then
      build/new-jenkins/rspec-with-wait.sh "docker-compose --project-name canvas-lms0 exec -T canvas bundle exec rspec --options spec/spec.opts spec/selenium/performance/ --failure-exit-code 99"
    else
      build/new-jenkins/rspec-with-wait.sh "build/new-jenkins/rspec-tests.sh"
    fi
  fi
  last_status=$?
  set -e

  [[ ! $reruns_started ]] && echo "FINISHED"
  [[ $last_status == $success_status ]] && break

  if [[ $last_status != $success_status && $last_status != $test_failure_status ]]; then
    echo "unexpected exit code $last_status! perhaps the code is horribly broken :("
    break
  fi

  if [[ $last_status == $test_failure_status ]]; then
    runs_remaining=$((runs_remaining-1))

    [[ $runs_remaining == 0 ]] && { echo "reruns failed $num_failures failure(s)"; break; }
    export ERROR_CONTEXT_BASE_PATH="/usr/src/app/log/spec_failures/Rerun_$runs_remaining"

    echo -e "failed, re-trying, $runs_remaining attempt(s) left\n\n\n"
    if [[ ! $reruns_started ]]; then
      reruns_started=1
      echo "RERUN STARTING"
    fi
  fi
done

[[ $reruns_started ]] && echo " FINISHED"
echo "rspec-queue-with-retries exiting with $last_status"
exit $last_status
