#!/bin/bash
export COMPOSE_FILE=./docker-compose.yml

docker-compose build
docker-compose up -d

# run unit tests
docker-compose exec -T module npm run test-cov
unit_status=$?
docker cp $(docker-compose ps -q module):/usr/src/app/coverage coverage

# check code formatting
docker-compose exec -T module npm run fmt:check
fmt_status=$?

# lint all the things
docker-compose exec -T module npm run lint
lint_status=$?

docker-compose stop

# jenkins uses the exit code to decide whether you passed or not
((unit_status)) && exit $unit_status
((lint_status)) && exit $lint_status
((fmt_status)) && exit $fmt_status
exit 0
