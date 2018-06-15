process.env.NODE_ENV = 'test'

const path = require('path')
const webpack = require('webpack')
const testWebpackConfig = require('./frontend_build/baseWebpackConfig')

testWebpackConfig.entry = undefined

testWebpackConfig.plugins.push(new webpack.EnvironmentPlugin({
  JSPEC_PATH: null,
  JSPEC_GROUP: null,
  A11Y_REPORT: false,
  SENTRY_DSN: null,
  GIT_COMMIT: null
}))

if (process.env.SENTRY_DSN) {
  const SentryCliPlugin = require('@sentry/webpack-plugin');
  testWebpackConfig.plugins.push(new SentryCliPlugin({
    release: process.env.GIT_COMMIT,
    include: [
      path.resolve(__dirname, 'public/javascripts'),
      path.resolve(__dirname, 'app/jsx'),
      path.resolve(__dirname, 'app/coffeescripts'),
      path.resolve(__dirname, 'spec/javascripts/jsx'),
      path.resolve(__dirname, 'spec/coffeescripts')
    ],
    ignore: [
      path.resolve(__dirname, 'public/javascripts/translations'),
      /bower\//
    ]
  }));
}


// These externals are necessary for Enzyme
// See http://airbnb.io/enzyme/docs/guides/webpack.html
Object.assign(testWebpackConfig.externals || (testWebpackConfig.externals = {}), {
  'react-dom/server': 'window',
  'react/lib/ReactContext': 'true',
  'react/lib/ExecutionEnvironment': 'true',
  'react-dom/test-utils': 'somethingThatDoesntActuallyExist',
  'react-test-renderer/shallow': 'somethingThatDoesntActuallyExist'
})

testWebpackConfig.resolve.alias['spec/jsx'] = path.resolve(__dirname, 'spec/javascripts/jsx')

testWebpackConfig.module.rules.unshift({
  test: [
    /\/spec\/coffeescripts\//,
    /\/spec_canvas\/coffeescripts\//,
    // Some plugins use a special spec_canvas path for their specs
    /\/spec\/javascripts\/jsx\//,
    /\/ember\/.*\/tests\//
  ],

  // Our spec files expect qunit's global `test`, `module`, `asyncTest` and `start` variables.
  // These imports loaders make it so they are avalable as local variables
  // inside of a closure, without truly making them globals.
  // We should get rid of this and just change our actual source to s/test/qunit.test/ and s/module/qunit.module/
  loaders: [
    'imports-loader?test=>QUnit.test',
  ]
})

module.exports = testWebpackConfig
