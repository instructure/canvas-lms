process.env.NODE_ENV = 'test'

const path = require('path')
const webpack = require('webpack')
const testWebpackConfig = require('./frontend_build/baseWebpackConfig')
const jspecEnv = require('./spec/jspec_env')

testWebpackConfig.entry = undefined
testWebpackConfig.plugins.push(new webpack.DefinePlugin(jspecEnv))

// These externals are necessary for Enzyme
// See http://airbnb.io/enzyme/docs/guides/webpack.html
Object.assign(testWebpackConfig.externals || (testWebpackConfig.externals = {}), {
  'react-dom/server': 'window',
  'react/lib/ReactContext': 'true',
  'react/lib/ExecutionEnvironment': 'true'
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
    'imports-loader?asyncTest=>QUnit.asyncTest',
    'imports-loader?start=>QUnit.start',
  ]
})

// For faster local debugging in karma, only add istambul cruft you've explicity set the "COVERAGE" environment variable
if (process.env.COVERAGE) {
  testWebpackConfig.module.rules.unshift({
    test: /(jsx.*(\.js$|\.jsx$)|\.coffee$|public\/javascripts\/.*\.js$)/,
    exclude: /(node_modules|spec|public\/javascripts\/(bower|client_apps|compiled|jst|jsx|translations|vendor))/,
    loader: 'istanbul-instrumenter-loader'
  })
}

module.exports = testWebpackConfig
