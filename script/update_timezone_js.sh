#!/bin/sh

pushd $(dirname $0)/..

pushd ..
  if [ ! -d timezone ]; then
    git clone https://github.com/bigeasy/timezone.git
  fi
popd

pushd ../timezone
  git fetch origin
  git reset --hard $1
  git submodule update --init
  make
popd

cp -R ../timezone/build/timezone/ public/javascripts/vendor/timezone/
rm -f public/javascripts/vendor/timezone/*/index.js
rm -f public/javascripts/vendor/timezone/*/*/index.js
rm -f public/javascripts/vendor/timezone/.npmignore
rm -f public/javascripts/vendor/timezone/index.js
rm -f public/javascripts/vendor/timezone/loaded.js
rm -f public/javascripts/vendor/timezone/rfc822.js
rm -f public/javascripts/vendor/timezone/synopsis.js
cp ../timezone/src/timezone.js public/javascripts/vendor/
git checkout -- public/javascripts/vendor/timezone/locales.js
git checkout -- public/javascripts/vendor/timezone/zones.js

for tz in public/javascripts/vendor/timezone/*.js public/javascripts/vendor/timezone/*/*.js public/javascripts/vendor/timezone/*/*/*.js; do
  sed -i '' 's/^ *//g' $tz
  tr -d '\n' < $tz > $tz.2
  mv $tz.2 $tz
  sed -i '' 's/: */:/g' $tz
  sed -i '' 's/^module.exports = /module.exports=/' $tz
  sed -i '' 's/^module.exports=\(.*\)$/define(function () { return \1 });/' $tz
  tr -d '\n' < $tz > $tz.2
  mv $tz.2 $tz
done

git add public/javascripts/vendor/timezone.js
git add public/javascripts/vendor/timezone/