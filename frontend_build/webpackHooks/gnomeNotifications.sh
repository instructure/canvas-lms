#!/bin/sh
export CANVAS_WEBPACK_START_HOOK='notify-send "Build Started" "Canvas Webpack build started"'
export CANVAS_WEBPACK_FAILED_HOOK='notify-send "Build Error" "Canvas Webpack build failed\"'
export CANVAS_WEBPACK_DONE_HOOK='notify-send "Build Finished" "Canvas Webpack build finished"'
