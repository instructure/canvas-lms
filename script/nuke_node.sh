#!/bin/bash

echo "removing node_modules and any cached/generated artifacts of any JS related files..."
git clean client_apps public spec/javascripts node_modules coverage-js gems/*/node_modules -Xfd

set -e
npm cache clean

echo "npm installing..."
npm install

echo "npm gems installing..."
script/gem_npm install

echo "everything's clean, now compiling assets..."
bundle exec rake canvas:compile_assets

