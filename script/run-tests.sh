#!/bin/bash
set -ev

# echo $STRONGMIND_SPEC
# echo $HEADLESS
# echo $TRAVIS_BUILD_DIR
# echo $SHIM_BRANCH

bundle _1.15.1_ exec rspec spec_strongmind
