#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

PROCESSES=$((${RSPEC_PROCESSES:=1}-1))

for i in $(seq 0 $PROCESSES); do
  WORKER_NAME="${JOB_NAME}_worker${CI_NODE_INDEX}-${i}"

  commands+=("RAILS_DB_NAME_TEST=canvas_test_${i} bundle exec rspecq \
                                          --build ${JOB_NAME}_build${BUILD_NUMBER} \
                                          --worker ${WORKER_NAME} \
                                          --include-pattern '${TEST_PATTERN}'  \
                                          --exclude-pattern '${EXCLUDE_TESTS}' \
                                          --junit-output log/results/junit{{JOB_INDEX}}-${i}.xml \
                                          --queue-wait-timeout 120 \
                                          -- --require './spec/formatters/error_context/stderr_formatter.rb' \
                                          --require './spec/formatters/error_context/html_page_formatter.rb' \
                                          --format ErrorContext::HTMLPageFormatter \
                                          --format ErrorContext::StderrFormatter .")
done

for command in "${commands[@]}"; do
  ./build/new-jenkins/linters/run-and-collect-output.sh "$command" 2>&1 &
  command_pids[$!]=$command
done

for command_pid in "${!command_pids[@]}"; do
  wait $command_pid || last_statuses[$command_pid]=$?
done
