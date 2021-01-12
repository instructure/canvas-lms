#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

source ./build/new-jenkins/docker-build-helpers.sh

MIGRATIONS_CACHE_MD5=$(find db/migrate/*.rb -type f -exec md5sum {} \; | sort -k 2 | md5sum | cut -d ' ' -f 1)

CASSANDRA_LOAD_TAG="$CASSANDRA_PREFIX:${CACHE_LOAD_SCOPE}-$MIGRATIONS_CACHE_MD5"
DYNAMODB_LOAD_TAG="$DYNAMODB_PREFIX:${CACHE_LOAD_SCOPE}-$MIGRATIONS_CACHE_MD5"
POSTGRES_LOAD_TAG="$POSTGRES_PREFIX:${CACHE_LOAD_SCOPE}-$MIGRATIONS_CACHE_MD5"

CASSANDRA_SAVE_TAG="$CASSANDRA_PREFIX:$CACHE_SAVE_SCOPE-$MIGRATIONS_CACHE_MD5"
DYNAMODB_SAVE_TAG="$DYNAMODB_PREFIX:$CACHE_SAVE_SCOPE-$MIGRATIONS_CACHE_MD5"
POSTGRES_SAVE_TAG="$POSTGRES_PREFIX:$CACHE_SAVE_SCOPE-$MIGRATIONS_CACHE_MD5"

CASSANDRA_UNIQUE_TAG="$CASSANDRA_PREFIX:$CACHE_UNIQUE_SCOPE"
DYNAMODB_UNIQUE_TAG="$DYNAMODB_PREFIX:$CACHE_UNIQUE_SCOPE"
POSTGRES_UNIQUE_TAG="$POSTGRES_PREFIX:$CACHE_UNIQUE_SCOPE"

if [ ! -z "$CACHE_LOAD_SCOPE" ] && has_remote_tags $CASSANDRA_LOAD_TAG $DYNAMODB_LOAD_TAG $POSTGRES_LOAD_TAG; then
  tag_remote_async "CASSANDRA_TAG_REMOTE_PID" $CASSANDRA_LOAD_TAG $CASSANDRA_UNIQUE_TAG
  tag_remote_async "DYNAMODB_TAG_REMOTE_PID" $DYNAMODB_LOAD_TAG $DYNAMODB_UNIQUE_TAG
  tag_remote_async "POSTGRES_TAG_REMOTE_PID" $POSTGRES_LOAD_TAG $POSTGRES_UNIQUE_TAG

  wait_for_children
  exit 0
fi

./build/new-jenkins/docker-compose-pull.sh
./build/new-jenkins/docker-compose-build-up.sh
./build/new-jenkins/docker-compose-setup-databases.sh

# Ensure that the DB shuts down cleanly and saves everything to disk.
docker stop $(docker ps -q --filter 'name=cassandra_' --filter 'name=dynamodb_' --filter 'name=postgres_')

CASSANDRA_MESSAGE="Cassandra migrated image for MD5SUM $MIGRATIONS_CACHE_MD5"
docker commit -m "$CASSANDRA_MESSAGE" $(docker ps -aq --filter 'name=cassandra_') $CASSANDRA_UNIQUE_TAG

DYNAMODB_MESSAGE="Dynamodb migrated image for MD5SUM $MIGRATIONS_CACHE_MD5"
docker commit -m "$DYNAMODB_MESSAGE" $(docker ps -aq --filter 'name=dynamodb_') $DYNAMODB_UNIQUE_TAG

POSTGRES_MESSAGE="Postgres migrated image for MD5SUM $MIGRATIONS_CACHE_MD5"
docker commit -m "$POSTGRES_MESSAGE" $(docker ps -aq --filter 'name=postgres_') $POSTGRES_UNIQUE_TAG

[ ! -z "$CACHE_SAVE_SCOPE" ] && docker tag $CASSANDRA_UNIQUE_TAG $CASSANDRA_SAVE_TAG
[ ! -z "$CACHE_SAVE_SCOPE" ] && docker tag $DYNAMODB_UNIQUE_TAG $DYNAMODB_SAVE_TAG
[ ! -z "$CACHE_SAVE_SCOPE" ] && docker tag $POSTGRES_UNIQUE_TAG $POSTGRES_SAVE_TAG

exit 0
