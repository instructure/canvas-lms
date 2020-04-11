#!/bin/bash

set -o errexit -o errtrace -o pipefail -o xtrace

ids=$(docker ps -aq --filter 'name=web_database_')
listID=( $ids )
for i in "${listID[@]}"
do
   docker cp $i:/usr/src/app/log/spec_failures/ ./tmp/spec_failures/web_database_$i || true
done
