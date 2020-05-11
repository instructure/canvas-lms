#!/bin/bash

set -o errexit -o errtrace -o pipefail

function show_usage_and_exit {
    echo ">> a tool for copying directories out of multiple docker containers

usage:
$(basename "$0") <container-dir> <host-dir> <container-name-filter> [--allow-error]
where:
    container-dir           the dir in the containers to copy files from
    host-dir                the dir to copy files to on the host machine
    container-name-filter   the value used in the docker filter
    --allow-error           allows the copy command to fail
    --clean-dir             clean the host dir before copying

example:
> docker ps
CONTAINER ID   IMAGE         NAMES
123            some-image    web_database_1
234            some-image    web_database_2
345            some-image    something_else
> $(basename "$0") /usr/src/app/logs tmp/logs web_database_
> find tmp/logs
tmp/logs
tmp/logs/web_database_123
tmp/logs/web_database_123/delayed_job.log
tmp/logs/web_database_123/production.log
tmp/logs/web_database_234
tmp/logs/web_database_234/production.log
tmp/logs/web_database_234/development.log
"
    exit 1
}

positional=()
allow_error=false
clean_dir=false

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --allow-error)
    allow_error=true
    shift
    ;;
    --clean-dir)
    clean_dir=true
    shift
    ;;
    *)
    positional+=("$1")
    shift
    ;;
esac
done

if [ "${#positional[@]}" != "3" ]; then
  echo "invalid number of arguments: ${positional[@]}"
  show_usage_and_exit
fi

container_dir="${positional[0]}"
host_dir="${positional[1]}"
search_name="${positional[2]}"

set -o xtrace

# ensure the state of the file system
if $clean_dir; then
  rm -rf $host_dir
fi
mkdir -p $host_dir

# get all the ids we'll be copying from
ids=( $(docker ps -aq --filter "name=$search_name") )

# actually do the copy
for i in "${ids[@]}"
do
  docker cp $i:$container_dir $host_dir/${search_name}_$i || $allow_error
done