#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

# get all changes
changes="$(git show --pretty="" --name-only HEAD^..HEAD | tr '\n' ' ')"
IFS=', ' read -r -a changesArray <<< "$changes"

# get only config/locales changes, exclude locales.yml and community.csv as those are ok to change alone
locales="$(git show --pretty=""  --name-only HEAD^..HEAD | grep "config/locales/" | grep -v "config/locales/locales.yml" | grep -v "config/locales/community.csv" | tr '\n' ' ')"
IFS=', ' read -r -a localesArray <<< "$locales"

# diff the two arrays, save any unique to diffArray
diffArray="$(echo "${localesArray[@]}" "${changesArray[@]}" | tr ' ' '\n' | sort | uniq -u)"

# if any diff, there is more than locales changes
# if no diff, there are only config/locales changes
[[ -z "$diffArray" ]]; exit $?
