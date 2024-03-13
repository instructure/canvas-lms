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

const isProduction = process.env.NODE_ENV === 'production'

const {
  swc,
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
  buildCacheOptions,
  controlAccessBetweenModules,
  customSourceFileExtensions,
  environmentVars,
  excludeMomentLocales,
  failOnWebpackWarnings,
  minimizeCode,
  moduleFederation,
  provideJQuery,
  readOnlyCache,
  setMoreEnvVars,
  timezoneData,
  webpackHooks,
  webpackManifest,
} = require('./webpack.plugins')

// generates bundles-generated.js with functions that
// dynamically import each plugin bundle
require('./generatePluginBundles')

// generates ui/shared/bundles/extensions.ts with functions that
// dynamically import each plugin extension
require('./generatePluginExtensions')

const skipSourcemaps = process.env.SKIP_SOURCEMAPS === '1'

const shouldWriteCache =
  process.env.WRITE_BUILD_CACHE === '1' || process.env.NODE_ENV !== 'production'

module.exports = {
  mode: isProduction ? 'production' : 'development',

  // infer platform and ES-features from @instructure/browserslist-config-canvas-lms
  target: ['browserslist'],

  // use file cache (instead of memory cache)
  // assumes that the cache is only reused when no build dependencies are changing.
  ...(process.env.USE_BUILD_CACHE === '1' ? buildCacheOptions : null),

  optimization: {
    // named: readable ids for better debugging
    // deterministic: smaller ids for better caching
    moduleIds: isProduction ? 'deterministic' : 'named',
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
      cacheGroups: {
        react: {
          test: /[\\/]node_modules[\\/](react|react-dom)[\\/]/,
          name: 'react',
          chunks: 'all',
        },
        defaultVendors: false,
      },
    },
  },

  // In prod build, don't attempt to continue if there are any errors.
  bail: isProduction,

  // style of source mapping to enhance the debugging process
  // https://webpack.js.org/configuration/devtool/
  devtool: skipSourcemaps
    ? false
    : isProduction || process.env.COVERAGE === '1'
    ? // "Recommended choice for production builds"
      'source-map'
    : // "Recommended choice for development builds"
      'eval-source-map',

  entry: {main: resolve(canvasDir, 'ui/index.ts')},

  watchOptions: {ignored: ['**/node_modules/']},

  externalsType: 'global',
  output: {
    publicPath: isProduction ? '/dist/webpack-production/' : '/dist/webpack-dev/',
    clean: true, // clean /dist folder before each build
    path: join(canvasDir, 'public', webpackPublicPath),
    hashFunction: 'xxhash64',
    filename: '[name]-entry-[contenthash].js',
    chunkFilename: '[name]-chunk-[contenthash].js',
  },

  resolve: {
    fallback: {
      // Called for by minimatch but as we use it, minimatch  can work without it
      path: false,
      timers: false,
      // several things need stream
      stream: require.resolve('stream-browserify'),
    },

    modules: [resolve(canvasDir, 'public/javascripts'), 'node_modules'],

    extensions: ['.js', '.jsx', '.ts', '.tsx'],
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

    rules: [
      process.env.CRYSTALBALL_MAP === '1' && istanbul, // adds ~20 seconds to build time
      instUIWorkaround,
      webpack5Workaround,
      css,
      images,
      fonts,
      ...swc,
      handlebars,
      emberHandlebars,
    ].filter(Boolean),
  },

  plugins: [
    environmentVars,
    isProduction && timezoneData, // adds 3-4 seconds to build time,
    customSourceFileExtensions,
    webpackHooks,
    controlAccessBetweenModules,
    setMoreEnvVars,
    provideJQuery,
    moduleFederation,
    !shouldWriteCache && readOnlyCache,
    process.env.WEBPACK_PEDANTIC !== '0' && failOnWebpackWarnings,
    process.env.NODE_ENV !== 'test' && excludeMomentLocales,
    // including the following prints this warning
    // "custom stage for process_assets is not supported yet, so Infinity is fallback to Compilation.PROCESS_ASSETS_STAGE_REPORT(5000)""
    webpackManifest,
  ].filter(Boolean),
}
