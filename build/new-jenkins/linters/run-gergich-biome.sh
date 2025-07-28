#!/bin/bash

set -e

if [ "${SKIP_BIOME-}" != "true" ]; then
  echo "Running Biome..."
  # We explicitly *don't* want to fail the build if Biome fails, as Gergich will give a -2 and
  # it might still be useful to see what tests failed.
  # The `--no-errors-on-unmatched` flag is used to avoid failing the build if there are unmatched files.
  gergich capture custom:./build/gergich/biome:Gergich::Biome 'yarn biome ci --since=HEAD^ --changed --reporter=github --no-errors-on-unmatched' || { echo "Biome check failed. Continuing the build"; exit 0; }
else
  echo "Skipping Biome..."
fi

