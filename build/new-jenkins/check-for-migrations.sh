#!/bin/bash

# grep will exit with code 0 if any commits between origin/master and
# HEAD contain db/migrate.
git show --pretty="" --name-only origin/master..HEAD | grep "db/migrate"
