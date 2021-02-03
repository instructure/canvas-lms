#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite ::: :

# Run each group of tests in separate docker container
seq 0 $((DOCKER_PROCESSES-1)) | parallel -u "docker-compose --project-name canvas-lms{} exec -T -e RSPEC_PROCESSES canvas bash -c 'build/new-jenkins/rspec-with-retries.sh'"
