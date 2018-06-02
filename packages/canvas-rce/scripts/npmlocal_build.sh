#!/usr/bin/env bash
# this will build an npm module for local distribution

output=$(npm pack 2> /dev/null)
file=`echo ${output} | sed "s/^.* //"`

mv ${file} /tmp/
echo "/tmp/${file}"