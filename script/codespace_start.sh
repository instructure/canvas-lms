#!/bin/bash
set -ex

# https://github.com/instructure/canvas-lms/wiki/Quick-Start#starting-it-again

export PGHOST=localhost
/usr/lib/postgresql/12/bin/pg_ctl start -D ~/postgresql-data/
bundle exec rails server
