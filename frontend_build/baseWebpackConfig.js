const fs = require('fs')
const glob = require('glob')
const ManifestPlugin = require('webpack-manifest-plugin')
const path = require('path')
const webpack = require('webpack')
const bundleEntries = require('./bundles')
const BundleExtensionsPlugin = require('./BundleExtensionsPlugin')
const ClientAppsPlugin = require('./clientAppPlugin')
const CompiledReferencePlugin = require('./CompiledReferencePlugin')
const I18nPlugin = require('./i18nPlugin')
const WebpackHooks = require('./webpackHooks')
const webpackPublicPath = require('./webpackPublicPath')

require('babel-polyfill')

if (!process.env.NODE_ENV) process.env.NODE_ENV = 'development'

const timezones = glob.sync('vendor/timezone/**/*.js', {cwd: 'public/javascripts'})
const momentLocales = glob.sync('moment/locale/**/*.js', {cwd: 'node_modules'})
const timezoneAndLocaleBundles = timezones.concat(momentLocales).reduce((memo, filename) =>
  Object.assign(memo, {[filename.replace(/.js$/, '')]: filename})
, {})

// this is to make our regexs to plugin things work with caturday, which uses symlinks
function pluginsRegex (pathPart) {
  const pluginsRoot = fs.realpathSync(path.resolve(__dirname, '../gems/plugins'))
  return RegExp(path.join(pluginsRoot, '.*', pathPart))
}

// Put any custom moment locales here:
timezoneAndLocaleBundles['moment/locale/mi-nz'] = 'custom_moment_locales/mi_nz.js'

module.exports = {
  // In prod build, don't attempt to continue if there are any errors.
  bail: process.env.NODE_ENV === 'production',

  // This makes the bundle appear split into separate modules in the devtools in dev/test.
  devtool: process.env.NODE_ENV === 'production' ? undefined : 'eval',

  entry: Object.assign({
    vendor: require('./modulesToIncludeInVendorBundle'),
    appBootstrap: 'jsx/appBootstrap'
  }, bundleEntries, timezoneAndLocaleBundles),

  output: {
    path: path.join(__dirname, '../public', webpackPublicPath),

    // Add /* filename */ comments to generated require()s in the output.
    pathinfo: process.env.NODE_ENV !== 'production',

    filename: '[name].bundle-[chunkhash:10].js',
    chunkFilename: '[name].chunk-[chunkhash:10].js',
    sourceMapFilename: '[file].[id]-[hash:10].sourcemap',
    jsonpFunction: 'canvasWebpackJsonp'
  },

  resolveLoader: {
    modules: ['node_modules', 'frontend_build']
  },

  resolve: {
    alias: {
      d3: 'd3/d3',
      old_version_of_react_used_by_canvas_quizzes_client_apps: path.resolve(__dirname, '../client_apps/canvas_quizzes/vendor/js/old_version_of_react_used_by_canvas_quizzes_client_apps'),
      handlebars: require.resolve('handlebars/dist/handlebars.runtime'),
      'node_modules-version-of-backbone': require.resolve('backbone'),
      'node_modules-version-of-react-modal': require.resolve('react-modal'),

      // once we are all-webpack we should remove this line and just change all the 'require's
      // to instructure-ui compnentns to have the right path
      'instructure-ui': path.resolve(__dirname, '../node_modules/instructure-ui/lib/components'),

      qtip: 'jquery.qtip',
      backbone: 'Backbone',
      timezone: 'timezone_core',
    },

    modules: [
      path.resolve(__dirname, '../public/javascripts'),
      path.resolve(__dirname, '../app'),
      path.resolve(__dirname, '../app/views'),
      path.resolve(__dirname, '../client_apps'),
      path.resolve(__dirname, '../gems/plugins'),
      path.resolve(__dirname, '../public/javascripts/vendor'), // for jqueryUI
      path.resolve(__dirname, '../client_apps/canvas_quizzes/vendor/js'),
      path.resolve(__dirname, '../client_apps/canvas_quizzes/vendor/packages'),
      'node_modules'
    ],

    extensions: [
      '.webpack.js',
      '.web.js',
      '.js',
      '.jsx',
      '.coffee',
      '.handlebars',
      '.hbs'
    ]
  },

  module: {
    // This can boost the performance when ignoring big libraries.
    // The files are expected to have no call to require, define or similar.
    // They are allowed to use exports and module.exports.
    noParse: [
      /vendor\/md5/,
      /tinymce\/tinymce/, // has 'require' and 'define' but they are from it's own internal closure
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
        test: /vendor\/i18n/,
        loaders: ['exports-loader?I18n']
      },

      {
        test: /vendor\/timezone\//,
        loaders: ['timezoneLoader']
      },


      {
        test: /\.js$/,
        include: path.resolve(__dirname, '../public/javascripts'),
        loaders: [
          'jsHandlebarsHelpers',
          'pluginsJstLoader',
        ]
      },
      {
        test: /\.jsx$/,
        include: [
          path.resolve(__dirname, '../app/jsx'),
          path.resolve(__dirname, '../spec/javascripts/jsx'),
          pluginsRegex('app/jsx')
        ],
        loaders: [
          // make sure we don't try to cache JSX assets when building for production
          `babel-loader${process.env.NODE_ENV === 'production' ? '' : '?cacheDirectory=tmp'}`
        ]
      },
      {
        test: /\.jsx$/,
        include: [/client_apps\/canvas_quizzes\/apps\//],
        loaders: ['jsx-loader']
      },
      {
        test: /\.coffee$/,
        include: [
          path.resolve(__dirname, '../app/coffeescript'),
          path.resolve(__dirname, '../spec/coffeescripts'),
          pluginsRegex('app/coffeescripts'),
          pluginsRegex('spec_canvas/coffeescripts')
        ],
        loaders: [
          'coffee-loader',
          'jsHandlebarsHelpers',
          'pluginsJstLoader'
        ]
      },
      {
        test: /\.handlebars$/,
        include: [
          path.resolve(__dirname, '../app/views/jst'),
          pluginsRegex('app/views/jst')
        ],
        loaders: ['i18nLinerHandlebars']
      },
      {
        test: /\.hbs$/,
        include: [
          /app\/coffeescripts\/ember\/screenreader_gradebook\/templates\//,
          /app\/coffeescripts\/ember\/shared\/templates\//
        ],
        loaders: ['emberHandlebars']
      },
      {
        test: require.resolve('../public/javascripts/vendor/jquery-1.7.2'),
        loader: 'exports-loader?window.jQuery'
      },
      {
        test: /node_modules\/handlebars\/dist\/handlebars\.runtime/,
        loader: 'exports-loader?Handlebars'
      },
      {
        test: /vendor\/md5/,
        loader: 'exports-loader?CryptoJS'
      }
    ]
  },

  plugins: [

    // A lot of our files expect a global `I18n` variable, this will provide it if it is used
    new webpack.ProvidePlugin({I18n: 'vendor/i18n'}),

    // sets these envirnment variables in compiled code.
    // process.env.NODE_ENV will make it so react and others are much smaller and don't run their
    // debug/proptype checking in prod.
    // if you need to do something in webpack that you don't do in requireJS, you can do
    // if (window.USE_WEBPACK) { // do something that will only happen in webpack}
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
      'window.USE_WEBPACK': JSON.stringify(true)
    }),

    // handles our custom 18n stuff
    new I18nPlugin(),

    // handles the the quiz stats and quiz log auditing client_apps
    new ClientAppsPlugin(),

    // tells webpack to look for 'compiled/foobar' at app/coffeescripts/foobar.coffee
    // instead of public/javascripts/compiled/foobar.js
    new CompiledReferencePlugin(),

    // handle the way we hook into bundles from our rails plugins like analytics
    new BundleExtensionsPlugin(),

    new WebpackHooks(),

  ].concat(process.env.NODE_ENV === 'test' ? [

    // in test mode, we do include all possible timezones in vendor/timezone/* into
    // the main bundle (see timezone_core.js). There are a few files in that dir
    // that are not js files, tell webpack to ignore them.
    new webpack.IgnorePlugin(/(CHANGELOG|LICENSE|README|\.md|package.json)$/, /vendor\/timezone/)

  ] : [

    // don't include any of the moment locales in the common bundle (otherwise it is huge!)
    // we load them explicitly onto the page in include_js_bundles from rails.
    new webpack.IgnorePlugin(/^\.\/locale$/, /^moment$/),

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
    // gets moment and timezone setup before any app code runs
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
