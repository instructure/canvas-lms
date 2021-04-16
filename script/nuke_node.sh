#!/bin/bash

set -e

echo "removing node_modules and any cached/generated artifacts of any JS related files..."
git clean packages public spec/javascripts node_modules coverage-js gems/*/node_modules packages/*/node_modules ui -Xfd
rm -rfv gems/plugins/*/node_modules

echo "yarn installing..."
yarn install

echo "everything's clean, now compiling assets..."
bundle exec rake canvas:compile_assets
