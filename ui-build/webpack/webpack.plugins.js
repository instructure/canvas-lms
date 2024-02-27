/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const {IgnorePlugin} = require('webpack')
const {
  DefinePlugin,
  ProvidePlugin,
  EnvironmentPlugin,
  SwcJsMinimizerRspackPlugin,
} = require('@rspack/core')
const {resolve} = require('path')
const MomentTimezoneDataPlugin = require('moment-timezone-data-webpack-plugin')
const EsmacPlugin = require('webpack-esmac-plugin')
const {WebpackManifestPlugin} = require('rspack-manifest-plugin')
const {RetryChunkLoadPlugin} = require('webpack-retry-chunk-load-plugin')
const {
  container: {ModuleFederationPlugin},
} = require('@rspack/core')
const WebpackHooks = require('./webpackHooks')
const {fetchSpeedGraderLibrary} = require('./remotes')

// determines which folder public assets are compiled to
const webpackPublicPath = require('./webpackPublicPath')

const {canvasDir} = require('../params')

exports.provideJQuery = new ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
})

// sets these environment variables in compiled code.
// process.env.NODE_ENV will make it so react and others are much smaller and don't run their
// debug/propType checking in prod.
exports.environmentVars = new EnvironmentPlugin({
  NODE_ENV: null,
  GIT_COMMIT: null,
  ALWAYS_APPEND_UI_TESTABLE_LOCATORS: null,
})

// Only include timezone data starting from 2011 (canvaseption) to 15 years from now,
// so we don't clutter the vendor bundle with a bunch of old timezone data
exports.timezoneData = new MomentTimezoneDataPlugin({
  startYear: 2011,
  endYear: new Date().getFullYear() + 15,
})

// hooks for webpack lifecycle (start, fail, done)
// requires process.env.ENABLE_CANVAS_WEBPACK_HOOKS
// write your own custom commands for:
//   CANVAS_WEBPACK_START_HOOK
//   CANVAS_WEBPACK_FAILED_HOOK
//   CANVAS_WEBPACK_DONE_HOOK
// cf. ui-build/webpack/webpackHooks/macNotifications.sh
exports.webpackHooks = new WebpackHooks()

// controls access between modules; enforces where you can import from
//   i.e. can't import features into packages, or ui/shared into packages
exports.controlAccessBetweenModules = new EsmacPlugin({
  test: /\.[tj]sx?$/,
  include: [
    resolve(canvasDir, 'ui/features'),
    resolve(canvasDir, 'ui/shared'),
    resolve(canvasDir, 'packages'),
    resolve(canvasDir, 'public/javascripts'),
    resolve(canvasDir, 'gems/plugins'),
  ],
  exclude: [/\/node_modules\//],
  formatter: require('./esmac/ErrorFormatter'),
  rules: require('./esmac/moduleAccessRules'),
  permit:
    process.env.WEBPACK_ENCAPSULATION_DEBUG === '1'
      ? []
      : require('./esmac/errorsPendingRemoval.json'),
})

exports.setMoreEnvVars = new DefinePlugin({
  CANVAS_WEBPACK_PUBLIC_PATH: JSON.stringify(webpackPublicPath),
  NODE_ENV: null,
  // webpack5 stopped providing a polyfill for process.env and its use in
  // web code is discouraged but a number of our dependencies still rely on
  // this, so we either selectively shim every property that they may be
  // referencing through the EnvironmentPlugin (below) and risk a hard
  // runtime error in case we didn't cover them all, or provide a sink like
  // this, which i'm gonna go with for now:
  process: {browser: true, env: {}},
})

// tries to load chunks if they fail to load
//   to resolve
exports.retryChunkLoading = new RetryChunkLoadPlugin({
  maxRetries: 3,
  retryDelay: `function(retryAttempt) { return retryAttempt * 1000 }`,
})

// prevents writing to the cache
exports.readOnlyCache = function (compiler) {
  compiler.cache.hooks.store.intercept({
    register: tapInfo => ({...tapInfo, fn: () => {}}),
  })
}

// return a non-zero exit code if there are any warnings so we don't
// continue compiling assets if webpack fails
exports.failOnWebpackWarnings = function (compiler) {
  compiler.hooks.done.tap('Canvas:FailOnWebpackWarnings', compilation => {
    if (compilation.warnings && compilation.warnings.length) {
      // eslint-disable-next-line no-console
      console.error(compilation.warnings)
      // If there's a bad import, webpack doesn't say where.
      // Only if we let the compilation complete do we get
      // the callstack where the import happens
      // If you're having problems, comment out the following
      throw new Error('webpack build had warnings. Failing.')
    }
  })
}

// don't include any of the moment locales in the common bundle
// (otherwise it is huge!) we load them explicitly onto the page in
// include_js_bundles from rails.
exports.excludeMomentLocales = new IgnorePlugin({
  resourceRegExp: /^\.\/locale$/,
  contextRegExp: /moment$/,
})

// generates asset manifests; maps features with chunks
//   outputs a json file so Rails knows which hash fingerprints to add
//   to each script url and so it knows which split chunks to make a
//   <link rel=preload ... /> for for each `js_bundle`
exports.webpackManifest = new WebpackManifestPlugin({
  fileName: 'webpack-manifest.json',
  publicPath: '',
  useEntryKeys: true,
})

exports.minimizeCode = new SwcJsMinimizerRspackPlugin({
  compress: {
    sequences: false, // prevents it from combining a bunch of statements with ","s so it is easier to set breakpoints
    // these are all things that terser does by default but we turn
    // them off because they don't reduce file size enough to justify the
    // time they take, especially after gzip:
    // see: https://slack.engineering/keep-webpack-fast-a-field-guide-for-better-build-performance-f56a5995e8f1
    booleans: false,
    collapse_vars: false,
    comparisons: false,
    computed_props: false,
    hoist_props: false,
    if_return: false,
    join_vars: false,
    keep_infinity: true,
    loops: false,
    negate_iife: false,
    properties: false,
    reduce_funcs: false,
    reduce_vars: false,
    typeofs: false,
  },
  output: {
    comments: false,
    semicolons: false, // prevents everything being on one line so it's easier to view in devtools
  },
})

exports.buildCacheOptions = {
  snapshot: {
    module: {hash: true, timestamp: false},
    resolve: {hash: true, timestamp: false},
  },
}

exports.moduleFederation = new ModuleFederationPlugin({
  name: 'canvas',
  remotes: {
    speedgrader: `promise new Promise(${fetchSpeedGraderLibrary.toString()})`,
  },
  exposes: {},
  shared: {},
})
