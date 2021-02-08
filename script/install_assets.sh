#!/bin/bash

set -o nounset -o errexit -o errtrace -o xtrace

# set up bundle config options \
bundle config --global build.nokogiri --use-system-libraries \
&& bundle config --global build.ffi --enable-system-libffi \
&& mkdir -p /home/docker/.bundle \
&& bundle install --jobs $(nproc)

yarn install --ignore-optional --pure-lockfile || yarn install --ignore-optional --pure-lockfile --network-concurrency 1

COMPILE_ASSETS_NPM_INSTALL=0 bundle exec rails canvas:compile_assets
