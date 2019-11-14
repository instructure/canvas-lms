#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

##
# This script loops through all available packages pulling out the english
# translations from each (/locales/en.json) and merges them together into a single
# en.json to be sent for translation
##

if ! [ -x "$(command -v jq)" ]; then
  echo 'jq not found.  Please install jq to use this script' >&2
  exit 1
fi

translation_dir="packages/translations/lib"
translation_file="$translation_dir/en.json"
mkdir -p "$translation_dir"
touch "$translation_file.tmp"

function finish {
  rm "$translation_file.tmp"
}
trap finish INT TERM EXIT

for pkg in packages/*; do
  if [ -f "$pkg/locales/en.json" ]; then
    cat "$pkg/locales/en.json" >> "$translation_file.tmp"
  fi
done

jq --slurp --sort-keys add < "$translation_file.tmp" > "$translation_file"
