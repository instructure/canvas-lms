#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

DOCKER_PROCESSES=${DOCKER_PROCESSES:-1}

# install extension on template1 which every new database is built from,
# so we don't have to run this more than once
psql -v ON_ERROR_STOP=1 --username postgres <<SQL
  \connect template1;
  CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public;
  CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;
  CREATE EXTENSION IF NOT EXISTS pg_collkey SCHEMA public;
  CREATE DATABASE canvas_test0
SQL
