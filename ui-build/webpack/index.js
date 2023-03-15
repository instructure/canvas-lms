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

// keep this in sync with webpack's dep version
const TerserPlugin = require('terser-webpack-plugin')
const MomentTimezoneDataPlugin = require('moment-timezone-data-webpack-plugin')
const path = require('path')
const glob = require('glob')
const webpack = require('webpack')
const {WebpackManifestPlugin} = require('webpack-manifest-plugin')
const WebpackHooks = require('./webpackHooks')
const SourceFileExtensionsPlugin = require('./SourceFileExtensionsPlugin')
const esmacPlugin = require('webpack-esmac-plugin')
const webpackPublicPath = require('./webpackPublicPath')
const {canvasDir} = require('#params')
const {RetryChunkLoadPlugin} = require('webpack-retry-chunk-load-plugin')

require('./bundles')

// We have a bunch of things (like our selenium jenkins builds) that have
// historically used the environment variable JS_BUILD_NO_UGLIFY to make their
// prod webpack builds go faster. But the slowest thing was not actually uglify
// (aka terser), it is generating the sourcemaps. Now that we added the
// performance hints and want to fail the build if you accidentally make our
// bundles larger than a certain size, we need to always uglify to check the
// after-uglify size of things, but can skip making sourcemaps if you want it to
// go faster. So this is to allow people to use either environment variable:
// the technically more correct SKIP_SOURCEMAPS one or the historically used JS_BUILD_NO_UGLIFY one.
const skipSourcemaps = Boolean(
  process.env.SKIP_SOURCEMAPS || process.env.JS_BUILD_NO_UGLIFY === '1'
)

// These flags are used by the build system to enable caching - it assumes that the cache is only reused
// when no build dependencies are changing.
const useBuildCache = process.env.USE_BUILD_CACHE === '1'
const writeBuildCache =
  process.env.WRITE_BUILD_CACHE === '1' || process.env.NODE_ENV === 'development'

const createBundleAnalyzerPlugin = (...args) => {
  const {BundleAnalyzerPlugin} = require('webpack-bundle-analyzer')
  return new BundleAnalyzerPlugin(...args)
}

const readOnlyCachePlugin = () => {
  return function apply(compiler) {
    compiler.cache.hooks.store.intercept({
      register: tapInfo => ({...tapInfo, fn: () => {}}),
    })
  }
}

module.exports = {
  mode: process.env.NODE_ENV,
  target: ['web', 'es2021'],
  ...((useBuildCache && {
    cache: {
      type: 'filesystem',
      allowCollectingMemory: false,
      buildDependencies: {config: []},
      compression: 'gzip',
    },
    snapshot: {
      buildDependencies: {hash: true, timestamp: false},
      module: {hash: true, timestamp: false},
      resolve: {hash: true, timestamp: false},
      resolveBuildDependencies: {hash: true, timestamp: false},
    },
  }) ||
    null),
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
    moduleIds: 'deterministic',
    minimizer: [
      new TerserPlugin({
        parallel: true,
        terserOptions: {
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
        },
      }),
    ],

    splitChunks: {
      name: false,

      // we can play with these numbers based on what we find to be the best tradeofffs with http2
      maxAsyncRequests: 30,
      maxInitialRequests: 10,

      chunks: 'all',
      cacheGroups: {defaultVendors: false}, // don't split out node_modules and app code in different chunks
    },
  },
  // In prod build, don't attempt to continue if there are any errors.
  bail: process.env.NODE_ENV === 'production',

  experiments: {
    backCompat: false,
  },

  devtool: skipSourcemaps
    ? false
    : process.env.NODE_ENV === 'production' || process.env.COVERAGE === '1'
    ? 'source-map'
    : 'eval',

  entry: {main: path.resolve(canvasDir, 'ui/index.js')},

  watchOptions: {
    ignored: ['**/node_modules/'],
  },

  output: {
    publicPath: '',
    clean: true,
    path: path.join(canvasDir, 'public', webpackPublicPath),
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
      underscore$: path.resolve(canvasDir, 'ui/shims/underscore.js'),
    },

    fallback: {
      // for minimatch module; it can work without path so let webpack know
      // instead of trying to resolve node's "path"
      path: false,
      // for parse-link-header, which requires "querystring" which is a node
      // module. btw we have at least 3 implementations of "parse-link-header"!
      querystring: require.resolve('querystring-es3'),
    },

    modules: [path.resolve(canvasDir, 'public/javascripts'), 'node_modules'],

    extensions: ['.js', '.ts', '.tsx'],
  },

  module: {
    parser: {
      javascript: {
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
      // packages that do specify "type": "module" for their package but are
      // still using non-fully qualified relative imports (e.g. "./foo"
      // instead of "./foo.js") are rejected by webpack 5, and this works
      // around it in the meantime
      //
      // to reproduce in the future, disable this rule block and verify that
      // webpack compiles successfully without errors like:
      //
      //     BREAKING CHANGE: The request '../jsutils/inspect' failed to
      //     resolve only because it was resolved as fully specified
      //
      // refs: https://github.com/webpack/webpack/issues/11467#issuecomment-691873586
      //       https://github.com/babel/babel/issues/12058
      //       https://github.com/graphql/graphql-js/issues/2721
      {
        test: /\.m?js$/,
        type: 'javascript/auto',
        include: [
          path.resolve(canvasDir, 'node_modules/graphql'),
          path.resolve(canvasDir, 'packages/datetime-moment-parser/index.js'),
          path.resolve(canvasDir, 'packages/datetime/index.js'),
        ],
        resolve: {
          fullySpecified: false,
        },
      },
      // remove when you no longer get an error from @instructure/ui* around
      // import/export with a package not marked as ESM:
      //
      //     ERROR in ./node_modules/@instructure/ui-view/es/index.js 24:0
      //     Module parse failed: 'import' and 'export' may appear only with 'sourceType: module' (24:0)
      //     You may need an appropriate loader to handle this file type, currently no loaders are configured to process this file. See https://webpack.js.org/concepts#loaders
      //
      {
        test: /\.js$/,
        type: 'javascript/auto',
        include: [
          path.resolve(canvasDir, 'node_modules/@instructure'),
          ...globPlugins('/node_modules/@instructure'),
        ],
      },
      {
        test: /\.(js|ts|tsx)$/,
        include: [
          path.resolve(canvasDir, 'ui'),
          path.resolve(canvasDir, 'packages/jquery-kyle-menu'),
          path.resolve(canvasDir, 'packages/jquery-popover'),
          path.resolve(canvasDir, 'packages/jquery-selectmenu'),
          path.resolve(canvasDir, 'packages/jquery-sticky'),
          path.resolve(canvasDir, 'packages/mathml'),
          path.resolve(canvasDir, 'packages/defer-promise'),
          path.resolve(canvasDir, 'packages/convert-case'),
          path.resolve(canvasDir, 'packages/html-escape'),
          path.resolve(canvasDir, 'packages/persistent-array'),
          path.resolve(canvasDir, 'packages/slickgrid'),
          path.resolve(canvasDir, 'packages/with-breakpoints'),
          path.resolve(canvasDir, 'spec/javascripts/jsx'),
          path.resolve(canvasDir, 'spec/coffeescripts'),
          ...globPlugins('app/{jsx,coffeescripts}/'),
        ],
        exclude: [/node_modules/],
        parser: {
          requireInclude: 'allow',
        },
        use: {
          loader: 'babel-loader',
          options: {
            configFile: false,
            cacheDirectory: process.env.NODE_ENV !== 'production',
            assumptions: {
              setPublicClassFields: true
            },
            env: {
              development: {
                plugins: ['babel-plugin-typescript-to-proptypes'],
              },
              production: {
                plugins: [
                  [
                    '@babel/plugin-transform-runtime',
                    {
                      helpers: true,
                      corejs: 3,
                      useESModules: true,
                    },
                  ],
                  'transform-react-remove-prop-types',
                  '@babel/plugin-transform-react-inline-elements',
                  '@babel/plugin-transform-react-constant-elements',
                ],
              },
            },
            presets: [
              ['@babel/preset-typescript'],
              [
                '@babel/preset-env',
                {
                  useBuiltIns: 'entry',
                  corejs: '3.20',
                  modules: false,
                  // This is needed to fix a Safari < 16 bug
                  // https://github.com/babel/babel/issues/14289
                  // https://bugs.webkit.org/show_bug.cgi?id=236843
                  include: ['@babel/plugin-proposal-class-properties'],
                },
              ],
              ['@babel/preset-react', {useBuiltIns: true}],
            ],
            targets: {
              browsers: 'last 2 versions',
              esmodules: true,
            },
          },
        },
      },
      {
        test: /\.coffee$/,
        include: [
          path.resolve(canvasDir, 'ui'),
          path.resolve(canvasDir, 'spec/coffeescripts'),
          ...globPlugins('{app,spec_canvas}/coffeescripts/'),
        ],
        use: ['coffee-loader'],
      },
      {
        test: /\.handlebars$/,
        include: [path.resolve(canvasDir, 'ui'), ...globPlugins('app/views/jst/')],
        use: [
          {
            loader: require.resolve('./i18nLinerHandlebars'),
            options: {
              // brandable_css assets are not available in test
              injectBrandableStylesheet: process.env.NODE_ENV !== 'test',
            },
          },
        ],
      },
      {
        test: /\.hbs$/,
        include: [path.join(canvasDir, 'ui/features/screenreader_gradebook/jst')],
        use: [require.resolve('./emberHandlebars')],
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(png|svg|gif)$/,
        loader: 'file-loader',
      },
      {
        test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: 'file-loader',
      },
    ],
  },

  plugins: [
    // sets these environment variables in compiled code.
    // process.env.NODE_ENV will make it so react and others are much smaller and don't run their
    // debug/propType checking in prod.
    new webpack.EnvironmentPlugin({
      NODE_ENV: null,
      GIT_COMMIT: null,
      ALWAYS_APPEND_UI_TESTABLE_LOCATORS: null,
    }),

    // Only include timezone data starting from 2011 (canvaseption) to 15 years from now,
    // so we don't clutter the vendor bundle with a bunch of old timezone data
    new MomentTimezoneDataPlugin({
      startYear: 2011,
      endYear: new Date().getFullYear() + 15,
    }),

    // allow plugins to extend source files
    new SourceFileExtensionsPlugin({
      context: canvasDir,
      include: glob.sync(path.join(canvasDir, 'gems/plugins/*/package.json'), {absolute: true}),
      tmpDir: path.join(canvasDir, 'tmp/webpack-source-file-extensions'),
    }),

    new WebpackHooks(),

    new esmacPlugin({
      test: /\.[tj]sx?$/,
      include: [
        path.resolve(canvasDir, 'ui'),
        path.resolve(canvasDir, 'packages'),
        path.resolve(canvasDir, 'public/javascripts'),
        path.resolve(canvasDir, 'gems/plugins'),
      ],
      exclude: [/\/node_modules\//],
      formatter: require('./esmac/ErrorFormatter'),
      rules: require('./esmac/moduleAccessRules'),
      permit:
        process.env.WEBPACK_ENCAPSULATION_DEBUG === '1'
          ? []
          : require('./esmac/errorsPendingRemoval.json'),
    }),

    new webpack.DefinePlugin({
      CANVAS_WEBPACK_PUBLIC_PATH: JSON.stringify(webpackPublicPath),
      NODE_ENV: null,
      // webpack5 stopped providing a polyfill for process.env and its use in
      // web code is discouraged but a number of our dependencies still rely on
      // this, so we either selectively shim every property that they may be
      // referencing through the EnvironmentPlugin (below) and risk a hard
      // runtime error in case we didn't cover them all, or provide a sink like
      // this, which i'm gonna go with for now:
      process: {env: {}},
    }),

    new RetryChunkLoadPlugin({
      maxRetries: 3,
      retryDelay: `function(retryAttempt) { return retryAttempt * 1000 }`
    }),
  ]
    .concat(writeBuildCache ? [] : readOnlyCachePlugin())
    .concat(
      // return a non-zero exit code if there are any warnings so we don't continue compiling assets if webpack fails
      process.env.WEBPACK_PEDANTIC !== '0'
        ? function (compiler) {
            compiler.hooks.done.tap('Canvas:FailOnWebpackWarnings', compilation => {
              if (compilation.warnings && compilation.warnings.length) {
                console.error(compilation.warnings)
                // If there's a bad import, webpack doesn't say where.
                // Only if we let the compilation complete do we get
                // the callstack where the import happens
                // If you're having problems, comment out the following
                throw new Error('webpack build had warnings. Failing.')
              }
            })
          }
        : []
    )
    .concat(
      process.env.WEBPACK_ANALYSIS === '1'
        ? createBundleAnalyzerPlugin({
            analyzerMode: 'static',
            reportFilename: process.env.WEBPACK_ANALYSIS_FILE
              ? path.resolve(process.env.WEBPACK_ANALYSIS_FILE)
              : path.resolve(canvasDir, 'tmp/webpack-bundle-analysis.html'),
            openAnalyzer: false,
            generateStatsFile: false,
            statsOptions: {
              source: false,
            },
          })
        : []
    )
    .concat(
      process.env.NODE_ENV === 'test'
        ? []
        : [
            // don't include any of the moment locales in the common bundle
            // (otherwise it is huge!) we load them explicitly onto the page in
            // include_js_bundles from rails.
            new webpack.IgnorePlugin({
              resourceRegExp: /^\.\/locale$/,
              contextRegExp: /moment$/,
            }),

            // outputs a json file so Rails knows which hash fingerprints to add
            // to each script url and so it knows which split chunks to make a
            // <link rel=preload ... /> for for each `js_bundle`
            new WebpackManifestPlugin({
              fileName: 'webpack-manifest.json',
              publicPath: '',
              useEntryKeys: true,
            }),
          ]
    ),
}

// since istanbul-instrumenter-loader adds so much overhead, only use it when generating crystalball map
if (process.env.CRYSTALBALL_MAP === '1') {
  module.exports.module.rules.unshift({
    test: /\.(js|ts|tsx)$/,
    include: [
      path.resolve(canvasDir, 'ui'),
      path.resolve(canvasDir, 'packages/jquery-kyle-menu'),
      path.resolve(canvasDir, 'packages/jquery-sticky'),
      path.resolve(canvasDir, 'packages/jquery-popover'),
      path.resolve(canvasDir, 'packages/jquery-selectmenu'),
      path.resolve(canvasDir, 'packages/mathml'),
      path.resolve(canvasDir, 'packages/persistent-array'),
      path.resolve(canvasDir, 'packages/slickgrid'),
      path.resolve(canvasDir, 'packages/with-breakpoints'),
      path.resolve(canvasDir, 'spec/javascripts/jsx'),
      path.resolve(canvasDir, 'spec/coffeescripts'),
      ...globPlugins('app/{jsx,coffeescripts}/'),
    ],
    exclude: [/test\//, /spec/],
    use: {
      loader: 'coverage-istanbul-loader',
      options: {esModules: true, produceSourceMap: true},
    },
    enforce: 'post',
  })
}

function globPlugins(pattern) {
  return glob.sync(`gems/plugins/*/${pattern}`, {
    absolute: true,
    cwd: canvasDir,
  })
}
