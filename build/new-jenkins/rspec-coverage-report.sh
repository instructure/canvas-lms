#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# lets see what in this before we start working on it
find ./coverage_nodes

rm -vrf coverage_reports
mkdir -v coverage_reports
chmod -vv 777 coverage_reports

python3 ./build/new-jenkins/rspec-combine-coverage-results.py

# build the reports inside the canvas-lms image because it has the required executables
inputs=()
inputs+=("--volume $(pwd)/coverage_nodes:/usr/src/app/coverage_nodes")
inputs+=("--volume $(pwd)/coverage_reports:/usr/src/app/coverage_reports")
cat <<EOF | docker run --interactive ${inputs[@]} $PATCHSET_TAG /bin/bash -
set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

mkdir -v coverage

# copy the file to where the 'merger' expects it
cp -v coverage_nodes/.resultset.json coverage/.resultset.json

# this doesnt actually merge things, it just makes the report
bundle exec ruby spec/simple_cov_result_merger.rb

# tar this up in the mounted volume so we can get it later
tar vcf coverage_reports/coverage.tar ./coverage
EOF

# extract the reports
rm -vrf coverage
tar -vxf coverage_reports/coverage.tar

# lets see the result after
find ./coverage
rm -vrf coverage_reports
