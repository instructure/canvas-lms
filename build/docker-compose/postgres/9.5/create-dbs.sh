#!/bin/bash

for thread in $(seq 1 $MASTER_RUNNERS); do
  [[ $thread == "1" ]] && thread=""
  cat <<SQL
    CREATE DATABASE canvas_test_$thread;
    \connect canvas_test_$thread
    CREATE EXTENSION pg_trgm SCHEMA public;
    CREATE EXTENSION postgis SCHEMA public;
SQL
done | psql -v ON_ERROR_STOP=1 --username postgres
