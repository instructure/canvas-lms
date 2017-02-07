const path = require('path')
const webpack = require('webpack')
const testWebpackConfig = require('./frontend_build/baseWebpackConfig')
const jspecEnv = require('./spec/jspec_env')

// the ember specs don't play nice with the rest,
// so we run them in totally seperate bundles
testWebpackConfig.entry = (process.env.WEBPACK_TEST_BUNDLE === 'ember')
  ? {WebpackedEmberSpecs: './spec/javascripts/webpack_ember_spec_index.js'}
  : {WebpackedSpecs: './spec/javascripts/webpack_spec_index.js'}

testWebpackConfig.output.path = path.resolve(__dirname, 'spec/javascripts/webpack')
testWebpackConfig.output.publicPath = '/base/spec/javascripts/webpack/'
testWebpackConfig.output.filename = '[name].bundle.test.js';

testWebpackConfig.plugins = testWebpackConfig.plugins.concat([
  // expose a 'qunit' global variable to any file that uses it
  new webpack.ProvidePlugin({qunit: 'qunitjs'}),

  new webpack.DefinePlugin(jspecEnv)
]);

// These externals are necessary for Enzyme
// See http://airbnb.io/enzyme/docs/guides/webpack.html
testWebpackConfig.externals = testWebpackConfig.externals || {};
testWebpackConfig.externals['react-dom/server'] = 'window';
testWebpackConfig.externals['react/lib/ReactContext'] = 'true';
testWebpackConfig.externals['react/lib/ExecutionEnvironment'] = 'true';

testWebpackConfig.resolve.alias.qunit = 'qunitjs';
testWebpackConfig.resolve.modules.push(path.resolve(__dirname, 'spec/coffeescripts'))
testWebpackConfig.resolve.modules.push(path.resolve(__dirname, 'spec/javascripts/support'))
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
    'imports-loader?test=>qunit.test',
    'imports-loader?asyncTest=>qunit.asyncTest',
    'imports-loader?start=>qunit.start',
    'qunitDependencyLoader'
  ]
})

// For easier local debugging in karma, only add istambul cruft if running on jenkins
// or you've explicity set the "JS_CODE_COVERAGE" environment variable
if (process.env.JENKINS_HOME || process.env.JS_CODE_COVERAGE) {
  testWebpackConfig.module.rules.unshift({
    test: /(jsx.*(\.js$|\.jsx$)|\.coffee$|public\/javascripts\/.*\.js$)/,
    exclude: /(node_modules|spec|public\/javascripts\/(bower|client_apps|compiled|jst|jsx|translations|vendor))/,
    loader: 'istanbul-instrumenter-loader'
  })
}

testWebpackConfig.module.noParse = testWebpackConfig.module.noParse.concat([
  /\/sinon-1.17.2.js/,
  /\/axe.js/
])

module.exports = testWebpackConfig
