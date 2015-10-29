var webpack = require("webpack");
var I18nPlugin = require("./i18nPlugin");
var ClientAppsPlugin = require("./clientAppPlugin");
var CompiledReferencePlugin = require("./CompiledReferencePlugin");
var bundleEntries = require("./bundles");
var ShimmedAmdPlugin = require("./shimmedAmdPlugin");
var BundleExtensionsPlugin = require("./BundleExtensionsPlugin");

module.exports = {
  devtool: 'eval',
  entry: bundleEntries,
  output: {
    path: __dirname + '/../public/webpack-dist',
    filename: "[name].bundle.js",
    chunkFilename: "[id].bundle.js",
    publicPath: "/webpack-dist/"
  },
  resolveLoader: {
    modulesDirectories: ['node_modules','frontend_build']
  },
  resolve: {
    alias: {
      qtip: "jquery.qtip",
      realTinymce: "bower/tinymce/tinymce",
      'ic-ajax': "bower/ic-ajax/dist/amd/main",
      'ic-tabs': "bower/ic-tabs/dist/amd/main",
      'bower/axios/dist/axios': 'bower/axios/dist/axios.amd'
    },
    modulesDirectories: [
      'app',
      'app/views',
      'client_apps',
      'gems/plugins',
      'public/javascripts',
      'public/javascripts/vendor',
      'node_modules',
      "client_apps/canvas_quizzes/vendor/js",
      "client_apps/canvas_quizzes/vendor/packages"
    ],
    extensions: [
      "",
      ".webpack.js",
      ".web.js",
      ".js",
      ".jsx",
      ".coffee",
      ".handlebars",
      ".hbs"
    ]
  },
  module: {
    preLoaders: [],
    loaders: [
      {
        test: /\.js$/,
        loaders: [
          "jsHandlebarsHelpers",
          "pluginsJstLoader",
          "nonAmdLoader"
        ]
      },
      {
        test: /\.jsx$/,
        exclude: /(node_modules|bower_components)/,
        loaders: [
          'babel',
          'jsxYankPragma'
        ]
      },
      {
        test: /\.coffee$/,
        loaders: [
          "coffee-loader",
          "jsHandlebarsHelpers",
          "pluginsJstLoader",
          "nonAmdLoader"
        ] },
      {
        test: /\.handlebars$/,
        loaders: [
          "i18nLinerHandlebars"
        ]
      },
      {
        test: /\.hbs$/,
        loaders: [
          "emberHandlebars"
        ]
      },
      {
        test: /\.json$/,
        loader: "json-loader"
      },
      {
        test: /vendor\/jquery-1\.7\.2/,
        loader: "exports-loader?window.jQuery"
      },
      {
        test: /bower\/handlebars\/handlebars\.runtime/,
        loader: "exports-loader?Handlebars"
      },
      {
        test: /vendor\/md5/,
        loader: "exports-loader?CryptoJS"
      }
    ]
  },
  plugins: [
    new I18nPlugin(),
    new ShimmedAmdPlugin(),
    new ClientAppsPlugin(),
    new CompiledReferencePlugin(),
    new BundleExtensionsPlugin(),
    new webpack.optimize.DedupePlugin(),
    new webpack.optimize.CommonsChunkPlugin({
      names: ["instructure-common", "vendor"],
      minChunks: Infinity
    }),
    new webpack.IgnorePlugin(/\.md$/),
    new webpack.IgnorePlugin(/(CHANGELOG|LICENSE|README)$/),
    new webpack.IgnorePlugin(/package.json/)
  ]
};
