#!/bin/bash

function generate_coverage_message() {
  statements=$(cat 'coverage/index.html' | grep -B 1 'Statements' | head -1 | egrep -o '1?[0-9]+\.?[0-9]+\%')
  branches=$(cat 'coverage/index.html' | grep -B 1 'Branches' | head -1 | egrep -o '1?[0-9]+\.?[0-9]+\%')
  functions=$(cat 'coverage/index.html' | grep -B 1 'Functions' | head -1 | egrep -o '1?[0-9]+\.?[0-9]+\%')
  lines=$(cat 'coverage/index.html' | grep -B 1 'Lines' | head -1 | egrep -o '1?[0-9]+\.?[0-9]+\%')

  echo -e "\nCode Coverage:\n\nStatements: ${statements} | Branches: ${branches} | Functions: ${functions} | Lines: ${lines}\n\nhttps://code-coverage.inseng.net/canvas-planner/coverage/index.html"
}

function cleanup() {
  exit_code=$?

  : "Cleaning up..."
  docker-compose stop
  docker-compose rm -f

  : "Finished!"
  exit $exit_code
}
trap cleanup INT TERM EXIT

set -ex

: 'Building docker images'
docker-compose build

: 'Running linter'
docker-compose run --rm test yarn run lint | gergich capture eslint -
gergich status


: 'Running tests'
docker-compose run --rm test yarn run test:coverage

: 'Starting containers'
docker-compose up -d

: 'Publishing coverage'
docker cp $(docker-compose ps -q test):/usr/src/app/coverage/. coverage

: 'Reporting coverage to gergich'
message=$(generate_coverage_message)
gergich message "$message"

: 'Publishing to gergich'
[[ ${GERGICH_KEY} || ${GERGICH_USER} ]] && gergich publish
