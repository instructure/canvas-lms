#!/bin/bash
set -o errexit -o errtrace -o nounset -o pipefail

DANGER_FILE_SIZE=1000000

cd /usr/src/app/public/dist/webpack-production
ls -ltra
for file in *.js; do
  filesize=$(ls -l $file | awk '{print $5}')
  if [ $filesize -gt $DANGER_FILE_SIZE ]; then
    echo "$file,$filesize" >> /tmp/big_bundles.csv
  fi
done