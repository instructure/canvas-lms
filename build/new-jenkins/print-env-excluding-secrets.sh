#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker -v
docker-compose -v

# filter secrets that end in "_KEY" or "_SECRET" but still mention their presence
printenv | sort | sed -E 's/(.*_(KEY|SECRET))=.*/\1 is present/g'
