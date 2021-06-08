#!/bin/bash

# grep will exit with code 0 if any commits between HEAD^ and
# HEAD contain db/migrate.
git show --pretty="" --name-only HEAD^..HEAD | grep "db/migrate"
