#!/bin/bash

#
# pidfile will get left behind when debugging is terminated,
# we need to clean it up to avoid "server is already running"
#
PIDFILE="/usr/src/app/tmp/pids/server.pid"

if [ -f "$PIDFILE" ]; then 
  rm "$PIDFILE"
fi

bin/rdebug-ide \
  --host 0.0.0.0 \
  --port 1234 --dispatcher-port 26162 \
  --skip-wait-for-start \
  -- \
  bin/rails s -p 80 -b 0.0.0.0
