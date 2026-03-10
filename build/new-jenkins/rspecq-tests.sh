#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

SPECS="${CRYSTAL_BALL_SPECS:=.}"
BUILD_NAME="${BUILD_NAME:=${JOB_NAME}_build${BUILD_NUMBER}}"
WORKER_NAME="${JOB_NAME}_worker${CI_NODE_INDEX}-${PARALLEL_INDEX}"
EXCLUDE_TESTS="${EXCLUDE_TESTS:-}"

EXCLUDE_PATTERN_ARG=()
if [[ -n "${EXCLUDE_TESTS}" ]]; then
  EXCLUDE_PATTERN_ARG=(--exclude-pattern "${EXCLUDE_TESTS}")
fi

bundle exec rspecq \
  --build "${BUILD_NAME}" \
  --worker "${WORKER_NAME}" \
  --include-pattern "${TEST_PATTERN}" \
  "${EXCLUDE_PATTERN_ARG[@]}" \
  --junit-output "log/results/junit{{JOB_INDEX}}-${PARALLEL_INDEX}.xml" \
  --queue-wait-timeout 120 \
  -- --require './spec/formatters/error_context/stderr_formatter.rb' \
     --require './spec/formatters/error_context/html_page_formatter.rb' \
     --require './spec/formatters/skip_tracker_formatter.rb' \
     --format ErrorContext::HTMLPageFormatter \
     --format ErrorContext::StderrFormatter \
     --format RSpec::SkipTrackerFormatter \
     ${SPECS}
