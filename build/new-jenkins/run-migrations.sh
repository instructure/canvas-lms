#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# Append thread count used to build images.
TAG_THREADS_SUFFIX=${RSPEC_PROCESSES:-"1"}

export CACHE_VERSION="2021-01-15.1"
export CACHE_SUFFIX="-$TAG_THREADS_SUFFIX"

source ./build/new-jenkins/docker-build-helpers.sh

MIGRATIONS_CACHE_MD5=$(find db/migrate/*.rb -type f -exec md5sum {} \; | sort -k 2 | md5sum | cut -d ' ' -f 1)

declare -A CASSANDRA_TAGS; compute_tags_from_hash "CASSANDRA_TAGS" $CASSANDRA_PREFIX $MIGRATIONS_CACHE_MD5
declare -A DYNAMODB_TAGS; compute_tags_from_hash "DYNAMODB_TAGS" $DYNAMODB_PREFIX $MIGRATIONS_CACHE_MD5
declare -A POSTGRES_TAGS; compute_tags_from_hash "POSTGRES_TAGS" $POSTGRES_PREFIX $MIGRATIONS_CACHE_MD5

if [ ! -z "$CACHE_LOAD_SCOPE" ] && has_remote_tags ${CASSANDRA_TAGS[LOAD_TAG]} ${DYNAMODB_TAGS[LOAD_TAG]} ${POSTGRES_TAGS[LOAD_TAG]}; then
  tag_remote_async "CASSANDRA_TAG_REMOTE_PID" ${CASSANDRA_TAGS[LOAD_TAG]} ${CASSANDRA_TAGS[UNIQUE_TAG]}
  tag_remote_async "DYNAMODB_TAG_REMOTE_PID" ${DYNAMODB_TAGS[LOAD_TAG]} ${DYNAMODB_TAGS[UNIQUE_TAG]}
  tag_remote_async "POSTGRES_TAG_REMOTE_PID" ${POSTGRES_TAGS[LOAD_TAG]} ${POSTGRES_TAGS[UNIQUE_TAG]}

  wait_for_children
  exit 0
fi

./build/new-jenkins/docker-compose-pull.sh
./build/new-jenkins/docker-compose-build-up.sh
./build/new-jenkins/docker-compose-setup-databases.sh

# Ensure that the DB shuts down cleanly and saves everything to disk.
docker stop $(docker ps -q --filter 'name=cassandra_' --filter 'name=dynamodb_' --filter 'name=postgres_')

CASSANDRA_MESSAGE="Cassandra migrated image for MD5SUM $MIGRATIONS_CACHE_MD5 with $TAG_THREADS_SUFFIX threads."
docker commit -m "$CASSANDRA_MESSAGE" $(docker ps -aq --filter 'name=cassandra_') ${CASSANDRA_TAGS[UNIQUE_TAG]}

DYNAMODB_MESSAGE="Dynamodb migrated image for MD5SUM $MIGRATIONS_CACHE_MD5 with $TAG_THREADS_SUFFIX threads."
docker commit -m "$DYNAMODB_MESSAGE" $(docker ps -aq --filter 'name=dynamodb_') ${DYNAMODB_TAGS[UNIQUE_TAG]}

POSTGRES_MESSAGE="Postgres migrated image for MD5SUM $MIGRATIONS_CACHE_MD5 with $TAG_THREADS_SUFFIX threads."
docker commit -m "$POSTGRES_MESSAGE" $(docker ps -aq --filter 'name=postgres_') ${POSTGRES_TAGS[UNIQUE_TAG]}

[ ! -z "$CACHE_SAVE_SCOPE" ] && docker tag ${CASSANDRA_TAGS[UNIQUE_TAG]} ${CASSANDRA_TAGS[SAVE_TAG]}
[ ! -z "$CACHE_SAVE_SCOPE" ] && docker tag ${DYNAMODB_TAGS[UNIQUE_TAG]} ${DYNAMODB_TAGS[SAVE_TAG]}
[ ! -z "$CACHE_SAVE_SCOPE" ] && docker tag ${POSTGRES_TAGS[UNIQUE_TAG]} ${POSTGRES_TAGS[SAVE_TAG]}

exit 0
