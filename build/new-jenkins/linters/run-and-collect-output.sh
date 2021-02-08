#!/bin/bash

# For the sake of output readability, don't print the trace.
set +ex

CMD=$1

# Buffer the output into a variable and print it all once the command
# has completed. This improves readability of the command output.
echo "=== RUN $CMD"
R=$(bash -c "$CMD" 2>&1); EXIT_CODE=$?
[ $EXIT_CODE -ne 0 ] && echo "=== FAILED $CMD"
echo "=== START OUTPUT $CMD"
echo "$R"
echo "=== END OUTPUT $CMD"

exit $EXIT_CODE
