#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# we have to premake the directories because for docker
# sub directories are problematic when making it on a mounted
# directory. permissions errors happen when making sub directories.
rm -vrf ./coverage-report-dir
mkdir -v coverage-report-dir
chmod -vvR 777 coverage-report-dir

# babel-plugin-istanbul will produce differently formatted
# coverage json files, this script cleans them up to be uniform and what
# istanbul-merge requires
node ./build/new-jenkins/js/cleanup-coverage.js '/usr/src/app/tmp/coverage-report-js' '/usr/src/app/coverage-report-dir/'

# aggregate them to coverage-total
./node_modules/.bin/istanbul-merge --out coverage-report-dir/coverage-total.json "coverage-report-dir/coverage-*-out.json"

# prepare for creating reports
mkdir -v .nyc_output
cp -v coverage-report-dir/coverage-total.json .nyc_output/total-coverage.json

# the html report
./node_modules/.bin/nyc report --reporter=html --report-dir report-html