#!/bin/bash
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# Fail fast if Webpack not configured
if [ ! -f config/WEBPACK ] && [[ ! ${USE_WEBPACK+x} ]]; then
    echo -e "${RED}Webpack must be enabled to use jspec${NC}"
    echo -e "${YELLOW}Run 'touch config/WEBPACK' to enable Webpack."
    echo -e "For more information, see the following documentation:"
    echo -e "  doc/working_with_webpack.md"
    echo -e "  doc/testing_javascript.md${NC}"
    exit
fi

export JSPEC_WD=$(pwd)

if [ "$1" == "--watch" ]; then
  export JSPEC_PATH=$2
  npm run webpack-test-watch --silent || true
else
  export JSPEC_PATH=$1
  npm run webpack-test --silent && npm run test --silent || true
fi
