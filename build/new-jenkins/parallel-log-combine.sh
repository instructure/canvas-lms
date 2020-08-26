#!/bin/bash
set -o errexit -o errtrace -o pipefail

find . -name 'parallel_runtime_*.log' -exec cat "{}" > combined_logs.log \;
awk '/^gems|spec/ {print "./" $0}' combined_logs.log | sort -f > parallel_runtime_rspec.log
