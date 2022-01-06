#!/bin/bash

set -ex

export COMPILE_ASSETS_NPM_INSTALL=0
export JS_BUILD_NO_FALLBACK=1
gergich capture custom:./build/gergich/compile_assets:Gergich::CompileAssets 'rake canvas:compile_assets'
yarn lint:browser-code
gergich status
echo "WEBPACK_BUILD OK!"
