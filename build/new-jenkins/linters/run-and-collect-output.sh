#!/bin/bash

# For the sake of output readability, don't print the trace.
set +ex

CMD=$1

# Buffer the output into a variable and print it all once the command
# has completed. This improves readability of the command output.
echo "=== RUN $CMD"

LOG_FILE=./log/cmd_output/interrupt-output-pid$$.log
mkdir -p "`dirname \"$LOG_FILE\"`"
echo "Writing to Log File: $(readlink -f $LOG_FILE)"
eval "$CMD" >> "$LOG_FILE" 2>&1; EXIT_CODE=$?

[ $EXIT_CODE -ne 0 ] && echo "=== FAILED $CMD"
echo "=== START OUTPUT $CMD"
cat "$LOG_FILE"
echo "=== END OUTPUT $CMD"

rm "$LOG_FILE"

exit $EXIT_CODE
