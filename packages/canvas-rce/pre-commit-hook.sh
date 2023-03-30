#!/usr/bin/env bash

#
# This file is executed automatically by /hooks/pre-commit if package files are changed
#

cd "$(dirname "$0")" || exit 1
PACKAGE_DIR=$(git rev-parse --show-prefix)

# Check typescript
if git diff --cached --name-only . | grep -qE '\.(ts|tsx)$'; then
  if [ -f node_modules/.bin/tsc ]; then
    echo "Checking $PACKAGE_DIR TypeScript..."
    node_modules/.bin/tsc
  else
    echo 'Trying to run tsc inside Docker. If you want things quicker yarn install locally.'
    docker-compose run --rm web node_modules/.bin/tsc
  fi

  if [ $? -ne 0 ]; then
    echo "TypeScript checking failed in $PACKAGE_DIR, aborting commit"
    exit 1
  fi
fi

# Note that eslint is handled by the root hook, so we don't need to do that here
