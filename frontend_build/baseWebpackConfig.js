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
const WebpackHooks = require('./webpackHooks')
const webpackPublicPath = require('./webpackPublicPath')
const HappyPack = require('happypack')
require('babel-polyfill')

const root = path.resolve(__dirname, '..')
const USE_BABEL_CACHE = process.env.NODE_ENV !== 'production' && process.env.DISABLE_HAPPYPACK === '1'

const momentLocaleBundles = glob.sync('moment/locale/**/*.js', {cwd: 'node_modules'}).reduce((memo, filename) =>
  Object.assign(memo, {[filename.replace(/.js$/, '')]: filename})
, {})

// Put any custom moment locales here:
momentLocaleBundles['moment/locale/mi-nz'] = 'custom_moment_locales/mi_nz.js'
momentLocaleBundles['moment/locale/ht-ht'] = 'custom_moment_locales/ht_ht.js'


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
      tempDir: 'node_modules/.happypack_tmp/',

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

  // This makes the bundle appear split into separate modules in the devtools in dev/test.
  devtool: process.env.NODE_ENV === 'production' ? undefined : 'eval',

  entry: Object.assign({
    vendor: require('./modulesToIncludeInVendorBundle'),
    appBootstrap: 'jsx/appBootstrap'
  }, bundleEntries, momentLocaleBundles),

  output: {
    path: path.join(__dirname, '../public', webpackPublicPath),

    // Add /* filename */ comments to generated require()s in the output.
    pathinfo: process.env.NODE_ENV !== 'production',

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
      handlebars: require.resolve('handlebars/dist/handlebars.runtime'),
      'node_modules-version-of-backbone': require.resolve('backbone'),
      'node_modules-version-of-react-modal': require.resolve('react-modal'),

      // once we are all-webpack we should remove this line and just change all the 'require's
      // to instructure-ui compnentns to have the right path
      'instructure-ui': path.resolve(__dirname, '../node_modules/instructure-ui/lib/components'),

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

    extensions: ['.js', '.jsx']
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
        test: /\.js$/,
        include: path.resolve(__dirname, '../public/javascripts'),
        loaders: happify('js', [
          path.join(root, 'frontend_build/jsHandlebarsHelpers'),
          path.join(root, 'frontend_build/pluginsJstLoader'),
        ])
      },
      {
        test: /\.jsx?$/,
        include: [
          path.resolve(__dirname, '../app/jsx'),
          path.resolve(__dirname, '../spec/javascripts/jsx'),
          /gems\/plugins\/.*\/app\/jsx\//
        ],
        loaders: happify('jsx', [
          `babel-loader?cacheDirectory=${USE_BABEL_CACHE}`
        ])
      },
      {
        test: /\.jsx?$/,
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
          'coffee-loader',
          path.join(root, 'frontend_build/jsHandlebarsHelpers'),
          path.join(root, 'frontend_build/pluginsJstLoader')
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
      },
      {
        test: /\.css$/,
        loader: 'style-loader!css-loader'
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

  ]
  .concat(happypackPlugins)
  .concat(process.env.NODE_ENV === 'test' ? [] : [

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
