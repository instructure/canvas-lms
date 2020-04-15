#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite : ::: ''

# Clone databases from canvas_test0
seq $((DOCKER_PROCESSES-1)) | parallel "DATABASE_NAME=canvas_test{} docker-compose exec -T postgres sh -c 'createdb -U postgres -T canvas_test0 canvas_test{}'"
seq $((DOCKER_PROCESSES-1)) | parallel "DATABASE_NAME=canvas_test{} docker-compose exec -T web bundle exec rails runner \"require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards\""

# Run each group of tests in separate docker container
seq 0 $((DOCKER_PROCESSES-1)) | parallel "DATABASE_NAME=canvas_test{} docker-compose run -T --name web_database_{} -e TEST_PROCESS={} web bash -c 'build/new-jenkins/rspec-with-retries.sh'"
