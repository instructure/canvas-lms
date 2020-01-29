#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# we have to premake the directories because... docker.. or something..
# sub directories are problematic when making it on a mounted
# directory. permissions errors happen when making sub directories.
rm -rf ./coverage-report-js
mkdir coverage-report-js
chmod -R 777 coverage-report-js

# copy all the coverage reports and rename them so there are no
# file name collisions
counter=0
for coverage_file in `find $WORKSPACE/tmp -name coverage*.json`
do
  echo $coverage_file
  cp $coverage_file ./coverage-report-js/coverage-$counter.json
  counter=$((counter+1))
done

# lets see whats inside the directory before we start aggregations
find ./coverage-report-js

# build the reports inside the canvas-lms image because it has the required executables
inputs=()
inputs+=("--volume $WORKSPACE/coverage-report-js:/usr/src/app/coverage-report-js")
cat <<EOF | docker run --interactive ${inputs[@]} $PATCHSET_TAG /bin/bash -
set -ex

# aggregate them to coverage-total
./node_modules/.bin/istanbul-merge --out coverage-report-js/coverage-total.json "coverage-report-js/coverage-*.json"

# prepare for creating reports
mkdir .nyc_output
cp coverage-report-js/coverage-total.json .nyc_output/total-coverage.json

# the html report
./node_modules/.bin/nyc report --reporter=html --report-dir report-html
tar cf coverage-report-js/report-html.tar report-html

# the json report
./node_modules/.bin/nyc report --reporter=json-summary --report-dir report-json
tar cf coverage-report-js/report-json.tar report-json
EOF

# extract the reports
tar -xf coverage-report-js/report-html.tar -C coverage-report-js/
tar -xf coverage-report-js/report-json.tar -C coverage-report-js/

# lets see the result after
find ./coverage-report-js
