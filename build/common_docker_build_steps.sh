#!/bin/bash

set -e

BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

function prompt {
  read -r -p "$1 " "$2"
}

function message {
  echo ''
  echo "$BOLD> $*$NORMAL"
}

function confirm_command {
  if [ -z "${JENKINS-}" ]; then
    prompt "OK to run '$*'? [y/n]" confirm
    [[ ${confirm:-n} == 'y' ]] || return 1
  fi
  eval "$*"
}

function create_db {
  # if Jenkins build, run initial_setup with rails test env to skip prompts
  if [ -n "${JENKINS-}" ]; then
    jenkinsBuild="-e RAILS_ENV=test"
  fi

  if ! docker-compose run --no-deps --rm web touch db/structure.sql; then
    message \
"The 'docker' user is not allowed to write to db/structure.sql. We need write
permissions so we can run migrations."
    touch db/structure.sql
    confirm_command 'chmod a+rw db/structure.sql' || true
  fi

  if database_exists; then
    message \
'An existing database was found.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
This script will destroy ALL EXISTING DATA if it continues
If you want to migrate the existing database, use docker_dev_update.sh
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    message 'About to run "bundle exec rake db:drop"'
    if [[ -z "$jenkinsBuild" ]]; then
      prompt "type NUKE in all caps: " nuked
      [[ ${nuked:-n} == 'NUKE' ]] || exit 1
    fi
    docker-compose run --rm web bundle exec rake db:drop
  fi

  message "Creating new database"
  docker-compose run --rm web \
    bundle exec rake db:create
  docker-compose run --rm web \
    bundle exec rake db:migrate
  docker-compose run ${jenkinsBuild} --rm web \
    bundle exec rake db:initial_setup
}

function build_images {
  message 'Building docker images...'
  docker-compose build --pull
}

function check_gemfile {
  if [[ -e Gemfile.lock ]]; then
    message \
'For historical reasons, the Canvas Gemfile.lock is not tracked by git. We may
need to remove it before we can install gems, to prevent conflicting depencency
errors.'
    confirm_command 'rm Gemfile.lock' || true
  fi

  # Fixes 'error while trying to write to `/usr/src/app/Gemfile.lock`'
  if ! docker-compose run --no-deps --rm web touch Gemfile.lock; then
    message \
"The 'docker' user is not allowed to write to Gemfile.lock. We need write
permissions so we can install gems."
    touch Gemfile.lock
    confirm_command 'chmod a+rw Gemfile.lock' || true
  fi
}

function database_exists {
  docker-compose run --rm web \
    bundle exec rails runner 'ActiveRecord::Base.connection' &> /dev/null
}
