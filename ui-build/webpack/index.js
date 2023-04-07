/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

const {resolve, join} = require('path')

// determines which folder public assets are compiled to
const webpackPublicPath = require('./webpackPublicPath')

// TODO: determine canvasDir and canvasComponents where needed
//   and remove this dependency
const {canvasDir} = require('../params')

const {
  babel,
  coffeescript,
  css,
  emberHandlebars,
  fonts,
  handlebars,
  images,
  istanbul,
  instUIWorkaround,
  webpack5Workaround,
} = require('./webpack.rules')

const {
  analyzeBundles,
  buildCacheOptions,
  controlAccessBetweenModules,
  customSourceFileExtensions,
  environmentVars,
  excludeMomentLocales,
  failOnWebpackWarnings,
  getDevtool,
  minimizeCode,
  readOnlyCache,
  retryChunkLoading,
  setMoreEnvVars,
  timezoneData,
  webpackHooks,
  webpackManifest,
} = require('./webpack.plugins')

// generates bundles-generated.js with functions that
// dynamically import each app feature and plugin bundle
require('./bundles')

if (!process.env.NODE_ENV) process.env.NODE_ENV = 'development'

// We have a bunch of things (like our selenium jenkins builds) that have
// historically used the environment variable JS_BUILD_NO_UGLIFY to make their
// prod webpack builds go faster. But the slowest thing was not actually uglify
// (aka terser), it is generating the sourcemaps. Now that we added the
// performance hints and want to fail the build if you accidentally make our
// bundles larger than a certain size, we need to always uglify to check the
// after-uglify size of things, but can skip making sourcemaps if you want it to
// go faster. So this is to allow people to use either environment variable:
// the technically more correct SKIP_SOURCEMAPS one or the historically used JS_BUILD_NO_UGLIFY one.
// TODO: only use SKIP_SOURCEMAPS
//   JS_BUILD_NO_UGLIFY only used in gulp
const skipSourcemaps = Boolean(
  process.env.SKIP_SOURCEMAPS || process.env.JS_BUILD_NO_UGLIFY === '1'
)

const shouldWriteCache =
  process.env.WRITE_BUILD_CACHE === '1' || process.env.NODE_ENV === 'development'

module.exports = {
  mode: process.env.NODE_ENV,

  // infer platform and ES-features from @instructure/browserslist-config-canvas-lms
  target: ['browserslist'],

  // use file cache (instead of memory cache)
  // assumes that the cache is only reused when no build dependencies are changing.
  ...(process.env.USE_BUILD_CACHE === '1' ? buildCacheOptions : null),

  performance: skipSourcemaps
    ? false
    : {
        // This just reflects how big the 'main' entry is at the time of writing. Every
        // time we get it smaller we should change this to the new smaller number so it
        // only goes down over time instead of growing bigger over time
        maxEntrypointSize: 1270000,
        // This is how big our biggest js bundles are at the time of writing. We should
        // first work to attack the things in `thingsWeKnowAreWayTooBig` so we can start
        // tracking them too. Then, as we work to get all chunks smaller, we should change
        // this number to the size of our biggest known asset and hopefully someday get
        // to where they are all under the default value of 250000 and then remove this
        // TODO: decrease back to 1200000 LS-1222
        // NOTE: if maxAssetSize changes, update: ~build/new-jenkins/library/vars/webpackStage.groovy
        maxAssetSize: 1400000,
      },

  optimization: {
    // named: readable ids for better debugging
    // deterministic: smaller ids for better caching
    moduleIds: process.env.NODE_ENV === 'production' ? 'deterministic' : 'named',
    minimizer: [minimizeCode],

    splitChunks: {
      // keep same name of chunks; don't change names unnecessarily
      name: false,

      // parallel requests when on-demand loading
      // we can play with these numbers based on what we find to be the best tradeofffs with http2
      maxAsyncRequests: 30,
      maxInitialRequests: 10,

      // which chunks will be selected for optimization
      chunks: 'all',
      cacheGroups: {defaultVendors: false}, // don't split out node_modules and app code in different chunks
    },
  },

  // In prod build, don't attempt to continue if there are any errors.
  bail: process.env.NODE_ENV === 'production',

  // style of source mapping to enhance the debugging process
  devtool: getDevtool(skipSourcemaps),

  // we don't yet use multiple entry points
  entry: {main: resolve(canvasDir, 'ui/index.js')},

  watchOptions: {ignored: ['**/node_modules/']},

  output: {
    publicPath: '',
    clean: true, // clean /dist folder before each build
    path: join(canvasDir, 'public', webpackPublicPath),
    hashFunction: 'xxhash64',

    // Add /* filename */ comments to generated require()s in the output.
    pathinfo: process.env.NODE_ENV !== 'production',

    // "e" is for "entry" and "c" is for "chunk"
    filename: '[name]-e-[chunkhash:10].js',
    chunkFilename: '[name]-c-[chunkhash:10].js',
  },

  parallelism: 5,

  resolve: {
    alias: {
      // TODO: replace our underscore usage with lodash
      underscore$: resolve(canvasDir, 'ui/shims/underscore.js'),
    },

    fallback: {
      // for minimatch module; it can work without path so let webpack know
      // instead of trying to resolve node's "path"
      path: false,
      // for parse-link-header, which requires "querystring" which is a node
      // module. btw we have at least 3 implementations of "parse-link-header"!
      querystring: require.resolve('querystring-es3'),
    },

    modules: [resolve(canvasDir, 'public/javascripts'), 'node_modules'],

    extensions: ['.js', '.ts', '.tsx', '.coffee'],
  },

  module: {
    parser: {
      javascript: {
        // on invalid export names
        exportsPresence: 'error',
        importExportsPresence: 'error',
        reexportExportsPresence: 'error',
      },
    },

    // This can boost the performance when ignoring big libraries.
    // The files are expected to have no call to require, define or similar.
    // They are allowed to use exports and module.exports.
    noParse: [require.resolve('jquery'), require.resolve('tinymce')],

    rules: [
      process.env.CRYSTALBALL_MAP === '1' && istanbul,
      instUIWorkaround,
      webpack5Workaround,
      css,
      images,
      fonts,
      babel,
      coffeescript,
      handlebars,
      emberHandlebars,
    ].filter(Boolean),
  },

  plugins: [
    environmentVars,
    timezoneData,
    customSourceFileExtensions,
    webpackHooks,
    controlAccessBetweenModules,
    setMoreEnvVars,
    retryChunkLoading,

    !shouldWriteCache && readOnlyCache,

    process.env.WEBPACK_PEDANTIC !== '0' && failOnWebpackWarnings,

    process.env.WEBPACK_ANALYSIS === '1' && analyzeBundles,

    process.env.NODE_ENV !== 'test' && excludeMomentLocales,

    process.env.NODE_ENV !== 'test' && webpackManifest,
  ].filter(Boolean),
}
