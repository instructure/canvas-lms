#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

cat <<SQL | psql -v ON_ERROR_STOP=1 --username postgres
  CREATE DATABASE canvas_test;
  \connect canvas_test;
  CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public;
  CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;
  CREATE EXTENSION IF NOT EXISTS pg_collkey SCHEMA public;

  CREATE DATABASE canvas;
  \connect canvas;
  CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public;
  CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;
  CREATE EXTENSION IF NOT EXISTS pg_collkey SCHEMA public;
SQL
