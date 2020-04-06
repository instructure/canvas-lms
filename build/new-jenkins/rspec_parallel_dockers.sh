#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace
parallel --will-cite

# Clone database
seq $((DOCKER_PROCESSES-1)) | parallel "docker-compose exec -T postgres sh -c 'createdb -U postgres -T template0 canvas_test{}'"
seq $((DOCKER_PROCESSES-1)) | parallel "docker-compose exec -T postgres sh -c 'pg_dump -U postgres canvas_test0 | psql -U postgres canvas_test{}'"
seq $((DOCKER_PROCESSES-1)) | parallel "docker-compose exec -T -e DATABASE_URL=postgres://postgres:sekret@postgres:5432/canvas_test{} web bundle exec rails runner \"require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards\""

# Run each group of tests in separate docker container
seq 0 $((DOCKER_PROCESSES-1)) | parallel "docker-compose run --name web_database_{} -T -e DATABASE_URL=postgres://postgres:sekret@postgres:5432/canvas_test{} -e TEST_PROCESS={} web bash -c 'build/new-jenkins/rspec-with-retries.sh'"
