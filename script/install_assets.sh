#!/bin/bash

set -o nounset -o errexit -o errtrace


function bundle_config_and_install() {
  # set up bundle config options \
  echo "Running bundle config and bundle install..."
  bundle config --global build.nokogiri --use-system-libraries &&
  bundle config --global build.ffi --enable-system-libffi &&
  mkdir -p /home/docker/.bundle &&
  bundle install --jobs $(nproc)
}

function yarn_install() {
  echo "Running yarn install..."
  yarn install || yarn install --network-concurrency 1
}

function compile_assets() {
  echo "Running compile assets dev (css and js only, no docs or styleguide)..."
  bundle exec rails canvas:compile_assets_dev
}

ALL_COMMANDS='y'
while getopts ":c:" opt; do
  case ${opt} in
    c )
      command=${OPTARG}
      if [ "$command" = "bundle" ]
      then
        BUNDLE_CONFIG='y'
        ALL_COMMANDS='n'
      elif [ "$command" = "yarn" ]
      then
        YARN_INSTALL='y'
        ALL_COMMANDS='n'
      elif [ "$command" = "compile" ]
      then
        COMPILE='y'
        ALL_COMMANDS='n'
      fi
      ;;
  esac
done

if [[ ${BUNDLE_CONFIG-n} = 'y' ]] || [[ ${ALL_COMMANDS-n} = 'y' ]]; then
  bundle_config_and_install
fi
if [[ ${YARN_INSTALL-n} = 'y' ]] || [[ ${ALL_COMMANDS-n} = 'y' ]]; then
  yarn_install
fi
if [[ ${COMPILE-n} = 'y' ]] || [[ ${ALL_COMMANDS-n} = 'y' ]]; then
  compile_assets
fi
