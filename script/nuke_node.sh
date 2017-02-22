#!/bin/bash

set -e

echo "removing node_modules and any cached/generated artifacts of any JS related files..."
git clean client_apps public spec/javascripts node_modules coverage-js gems/*/node_modules app/coffeescripts -Xfd

npm cache clean

echo "yarn installing..."
(yarn install || npm install)

echo "everything's clean, now compiling assets..."
bundle exec rake canvas:compile_assets

