#!/bin/bash
set -e
export TMP_APP_HOME="/tmp/assets/src/app/"

asset_dirs=(
               "node_modules/"
               "packages/js-utils/node_modules"
               "packages/js-utils/lib"
               "packages/js-utils/es"
               "packages/canvas-media/node_modules"
               "packages/canvas-media/lib"
               "packages/canvas-media/es"
               "packages/jest-moxios-utils/node_modules"
               "packages/k5uploader/node_modules"
               "packages/k5uploader/lib"
               "packages/k5uploader/es"
               "packages/canvas-planner/node_modules"
               "packages/canvas-planner/lib"
               "packages/canvas-planner/es"
               "packages/canvas-rce/node_modules"
               "packages/canvas-rce/lib"
               "packages/canvas-rce/es"
               "packages/canvas-rce/canvas"
               "packages/translations/node_modules"
               "packages/old-copy-of-react-14-that-is-just-here-so-if-analytics-is-checked-out-it-doesnt-change-yarn.lock/node_modules"
               "public/javascripts/translations"
               "public/dist"
               "log/"
               "config/locales/generated"
               "stylesheets/brandable_css_brands"
               "app/views/info"
               "pacts"
               "public/doc/api"
               ".yardoc"
               "reports"
               "tmp"
             )
umask 0000
[ ! -z "${MUTAGEN-}" ] && chown docker:docker /usr/src/app
function copy_if_needed() {
  if [ -f "$APP_HOME$1" ]; then
    if ! diff -q "$TMP_APP_HOME$1" "$APP_HOME$1"; then
        cp "$TMP_APP_HOME$1" "$APP_HOME$1"
    fi
  else
    cp "$TMP_APP_HOME$1" "$APP_HOME$1"
  fi
}

mkdir -p /tmp/assets/src
mount --bind /usr/src /tmp/assets/src
copy_if_needed Gemfile.lock
copy_if_needed yarn.lock
for dir in "${asset_dirs[@]}"; do
  if [ -d "$TMP_APP_HOME$dir" ]; then
    mkdir -p "$APP_HOME$dir"
    mount --bind "$TMP_APP_HOME$dir" "$APP_HOME$dir"
  fi
done
find "$TMP_APP_HOME"gems/ -maxdepth 3 -name 'node_modules' -type d -printf "%P\n" | xargs -I% sh -c "mkdir -p ${APP_HOME}gems/% && mount --bind ${TMP_APP_HOME}gems/% ${APP_HOME}gems/%"

exec gosu docker "$@"
