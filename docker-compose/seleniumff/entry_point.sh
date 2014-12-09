#!/bin/bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

if [ ! -e /opt/selenium/config.json ]; then
  echo No Selenium Node configuration file, the node-base image is not intended to be run directly. 1>&2
  exit 1
fi

function shutdown {
  kill -s SIGTERM $VNC_PID
  wait $VNC_PID

  kill -s SIGTERM $FLUXBOX_PID
  wait $FLUXBOX_PID

  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

# TODO: Look into http://www.seleniumhq.org/docs/05_selenium_rc.jsp#browser-side-logs

xvfb-run -e /dev/stdout --server-args="$DISPLAY -screen 0 $GEOMETRY -ac +extension RANDR" \
  java -jar /opt/selenium/selenium-server-standalone.jar &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
for i in $(seq 1 10)
do
  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  echo Waiting xvfb...
  sleep 0.5
done

fluxbox -display $DISPLAY &
FLUXBOX_PID=$!

x11vnc -forever -usepw -shared -rfbport 5900 -display $DISPLAY &
VNC_PID=$!

wait $NODE_PID
