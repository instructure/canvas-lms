#!/bin/bash
set -ev

# echo $STRONGMIND_SPEC
# echo $HEADLESS
# echo $TRAVIS_BUILD_DIR
# echo $SHIM_BRANCH

if [ ! -z "$SHIM_BRANCH" ]; then
  # echo 'Shim branch detected'

  cd vendor/canvas_shim
  git checkout $SHIM_BRANCH
  cd $TRAVIS_BUILD_DIR
fi

bundle exec rspec spec_strongmind
