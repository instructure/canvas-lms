#!/bin/sh
export CANVAS_WEBPACK_START_HOOK='osascript -e "display notification \"Canvas Webpack build started\" with title \"Build Started\""'
export CANVAS_WEBPACK_FAILED_HOOK='osascript -e "display notification \"Canvas Webpack build failed\" with title \"Build Error\""'
export CANVAS_WEBPACK_DONE_HOOK='osascript -e "display notification \"Canvas Webpack build finished\" with title \"Build Finished\""'
