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

if (!process.env.NODE_ENV) process.env.NODE_ENV = 'development'

const glob = require('glob')
const ManifestPlugin = require('webpack-manifest-plugin')
const path = require('path')
const webpack = require('webpack')
const bundleEntries = require('./bundles')
const BundleExtensionsPlugin = require('./BundleExtensionsPlugin')
const ClientAppsPlugin = require('./clientAppPlugin')
const CompiledReferencePlugin = require('./CompiledReferencePlugin')
const I18nPlugin = require('./i18nPlugin')
const SelinimumManifestPlugin = require('./SelinimumManifestPlugin')
const WebpackHooks = require('./webpackHooks')
const webpackPublicPath = require('./webpackPublicPath')
const WebpackCleanupPlugin = require('webpack-cleanup-plugin')
const HappyPack = require('happypack')
const momentLocaleBundles = require('./momentBundles')
require('babel-polyfill')

const root = path.resolve(__dirname, '..')
const USE_BABEL_CACHE = process.env.NODE_ENV !== 'production' && process.env.DISABLE_HAPPYPACK === '1'

const happypackPlugins = []
const getHappyThreadPool = (() => {
  let pool
  return () => pool || (pool = new HappyPack.ThreadPool({ size: 4 }))
})()

function happify (id, loaders) {
  if (process.env.DISABLE_HAPPYPACK !== '1') {
    happypackPlugins.push(new HappyPack({
      id,
      loaders,
      threadPool: getHappyThreadPool(),
      tempDir: (process.env.HAPPYPACK_TEMPDIR || 'node_modules/.happypack_tmp/'),

      // by default, we use the cache everywhere exept prod. but you can
      // set HAPPYPACK_CACHE environment variable to override
      cache: (typeof process.env.HAPPYPACK_CACHE === 'undefined' ?
        process.env.NODE_ENV !== 'production' :
        process.env.HAPPYPACK_CACHE === '1'
      ),
      cacheContext: {
        env: process.env.NODE_ENV
      }
    }))
    return [`happypack/loader?id=${id}`]
  }
  return loaders
}

module.exports = {
  // In prod build, don't attempt to continue if there are any errors.
  bail: process.env.NODE_ENV === 'production',

  // In production, and when not using JS_BUILD_NO_UGLIFY, generate separate sourcemap files.
  // In development, generate `eval` sourcemaps.
  devtool: process.env.NODE_ENV === 'production' ?
    (process.env.JS_BUILD_NO_UGLIFY ? undefined : 'source-map')
    : ((process.env.COVERAGE || process.env.SENTRY_DSN) ? 'source-map' : 'eval'),

  entry: Object.assign({
    vendor: require('./modulesToIncludeInVendorBundle'),
    appBootstrap: 'jsx/appBootstrap'
  }, bundleEntries, momentLocaleBundles),

  output: {
    // NOTE: hashSalt was added when HashedModuleIdsPlugin was installed, since
    // chunkhashes are insensitive to moduleid changes. It should be changed again
    // if this plugin is reconfigured or removed, or if there is another reason to
    // prevent previously cached assets from being mixed with those from the new build
    hashSalt: '2018-01-29',
    path: path.join(__dirname, '../public', webpackPublicPath),

    // Add /* filename */ comments to generated require()s in the output.
    pathinfo: true,

    filename: '[name].bundle-[chunkhash:10].js',
    chunkFilename: '[name].chunk-[chunkhash:10].js',
    sourceMapFilename: '[file].[id]-[chunkhash:10].sourcemap',
    jsonpFunction: 'canvasWebpackJsonp'
  },

  resolveLoader: {
    modules: ['node_modules', 'frontend_build']
  },

  resolve: {
    alias: {
      d3: 'd3/d3',
      'node_modules-version-of-backbone': require.resolve('backbone'),
      'node_modules-version-of-react-modal': require.resolve('react-modal'),

      backbone: 'Backbone',
      timezone$: 'timezone_core',
      jst: path.resolve(__dirname, '../app/views/jst'),
      jqueryui: path.resolve(__dirname, '../public/javascripts/vendor/jqueryui'),
      coffeescripts: path.resolve(__dirname, '../app/coffeescripts'),
      jsx: path.resolve(__dirname, '../app/jsx'),

      // stuff for canvas_quzzes client_apps
      'canvas_quizzes/apps': path.resolve(__dirname, '../client_apps/canvas_quizzes/apps'),
      qtip$: path.resolve(__dirname, '../client_apps/canvas_quizzes/vendor/js/jquery.qtip.js'),
      old_version_of_react_used_by_canvas_quizzes_client_apps$: path.resolve(__dirname, '../client_apps/canvas_quizzes/vendor/js/old_version_of_react_used_by_canvas_quizzes_client_apps.js'),
      'old_version_of_react-router_used_by_canvas_quizzes_client_apps$': path.resolve(__dirname, '../client_apps/canvas_quizzes/vendor/js/old_version_of_react-router_used_by_canvas_quizzes_client_apps.js')
    },

    modules: [
      path.resolve(__dirname, '../public/javascripts'),
      path.resolve(__dirname, '../gems/plugins'),
      'node_modules'
    ],

    extensions: ['.js']
  },

  module: {
    // This can boost the performance when ignoring big libraries.
    // The files are expected to have no call to require, define or similar.
    // They are allowed to use exports and module.exports.
    noParse: [
      /node_modules\/jquery\//,
      /vendor\/md5/,
      /tinymce\/tinymce/, // has 'require' and 'define' but they are from it's own internal closure
      /i18nliner\/dist\/lib\/i18nliner/ // i18nLiner has a `require('fs')` that it doesn't actually need, ignore it.
    ],
    rules: [
      // to get tinymce to work. see: https://github.com/tinymce/tinymce/issues/2836
      {
        test: require.resolve('tinymce/tinymce'),
        loaders: [
          'imports-loader?this=>window',
          'exports-loader?window.tinymce'
        ]
      },
      {
        test: /tinymce\/(themes|plugins)\//,
        loaders: ['imports-loader?this=>window']
      },

      {
        test: /\.js$/,
        include: [
          path.resolve(__dirname, '../public/javascripts'),
          path.resolve(__dirname, '../app/jsx'),
          path.resolve(__dirname, '../app/coffeescripts'),
          path.resolve(__dirname, '../spec/javascripts/jsx'),
          path.resolve(__dirname, '../spec/coffeescripts'),
          /gems\/plugins\/.*\/app\/jsx\//
        ],
        exclude: [
          path.resolve(__dirname, '../public/javascripts/translations'),
          /bower\//,
        ],
        loaders: happify('babel', [
          `babel-loader?cacheDirectory=${USE_BABEL_CACHE}`
        ])
      },
      {
        test: /\.js$/,
        include: [/client_apps\/canvas_quizzes\/apps\//],
        loaders: ['jsx-loader']
      },
      {
        test: /\.coffee$/,
        include: [
          path.resolve(__dirname, '../app/coffeescript'),
          path.resolve(__dirname, '../spec/coffeescripts'),
          /app\/coffeescripts\//,
          /gems\/plugins\/.*\/spec_canvas\/coffeescripts\//
        ],
        loaders: happify('coffee', [
          'coffee-loader'
        ])
      },
      {
        test: /\.handlebars$/,
        include: [
          path.resolve(__dirname, '../app/views/jst'),
          /gems\/plugins\/.*\/app\/views\/jst\//
        ],
        loaders: happify('handlebars-i18n', [
          'i18nLinerHandlebars'
        ])
      },
      {
        test: /\.hbs$/,
        include: [
          /app\/coffeescripts\/ember\/screenreader_gradebook\/templates\//,
          /app\/coffeescripts\/ember\/shared\/templates\//
        ],
        loaders: happify('handlebars-ember', [path.join(root, 'frontend_build/emberHandlebars')]),
      },
      {
        test: /\.json$/,
        exclude: /public\/javascripts\/vendor/,
        loader: 'json-loader'
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\.(png|svg|gif)$/,
        loader: 'file-loader'
      }
    ]
  },

  plugins: [

    // return a non-zero exit code if there are any warnings so we don't continue compiling assets if webpack fails
    function () {
      this.plugin('done', ({compilation}) => {
        if (compilation.warnings && compilation.warnings.length) {
          console.error(compilation.warnings)
          throw new Error('webpack build had warnings. Failing.')
        }
      })
    },

    // sets these environment variables in compiled code.
    // process.env.NODE_ENV will make it so react and others are much smaller and don't run their
    // debug/propType checking in prod.
    new webpack.EnvironmentPlugin(['NODE_ENV']),

    new WebpackCleanupPlugin({
      exclude: ['selinimum-manifest.json']
    }),

    // handles our custom i18n stuff
    new I18nPlugin(),

    // handles the the quiz stats and quiz log auditing client_apps
    new ClientAppsPlugin(),

    // tells webpack to look for 'compiled/foobar' at app/coffeescripts/foobar.coffee
    // instead of public/javascripts/compiled/foobar.js
    new CompiledReferencePlugin(),

    // handle the way we hook into bundles from our rails plugins like analytics
    new BundleExtensionsPlugin(),

    new WebpackHooks(),

    // avoids warnings caused by
    // https://github.com/graphql/graphql-language-service/issues/111, should
    // be removed when that issue is fixed
    new webpack.IgnorePlugin(/\.flow$/),

    new webpack.HashedModuleIdsPlugin({
      hashDigestLength: 10
    })
  ]
  .concat(process.env.SELINIMUM_RUN || process.env.SELINIMUM_CAPTURE ? [

    new SelinimumManifestPlugin()

  ] : [])
  .concat(happypackPlugins)
  .concat(process.env.NODE_ENV === 'test' ? [] : [

    // don't include any of the moment locales in the common bundle (otherwise it is huge!)
    // we load them explicitly onto the page in include_js_bundles from rails.
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),

    // outputs a json file so Rails knows which hash fingerprints to add to each script url
    new ManifestPlugin({fileName: 'webpack-manifest.json'}),

    // these multiple commonsChunks make it so anything in the vendor bundle,
    // or in the common bundle, won't get loaded any of our other app bundles.
    new webpack.optimize.CommonsChunkPlugin({
      name: 'vendor',
      // children: true,

      // ensures that no other module goes into the vendor chunk
      minChunks: Infinity
    }),
    // gets moment locale setup before any app code runs
    new webpack.optimize.CommonsChunkPlugin({
      name: 'appBootstrap',
      children: true
    }),
    new webpack.optimize.CommonsChunkPlugin({
      name: bundleEntries.common,
      children: true
    }),
  ])
}
