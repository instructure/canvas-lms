var webpack = require("webpack");
var I18nPlugin = require("./frontend_build/i18nPlugin");
var ClientAppsPlugin = require("./frontend_build/clientAppPlugin");
var CompiledReferencePlugin = require("./frontend_build/CompiledReferencePlugin");

var baseWebpackConfig = require("./frontend_build/baseWebpackConfig");
var testWebpackConfig = baseWebpackConfig;
var jspecEnv = require('./spec/jspec_env');

// the ember specs don't play nice with the rest,
// so we run them in totally seperate bundles
if (process.env.WEBPACK_TEST_BUNDLE == 'ember') {
  testWebpackConfig.entry = {
    'WebpackedEmberSpecs': "./spec/javascripts/webpack_ember_spec_index.js"
  }
} else {
  testWebpackConfig.entry = {
    'WebpackedSpecs': "./spec/javascripts/webpack_spec_index.js"
  }
}

testWebpackConfig.devtool = undefined;
testWebpackConfig.output.path = __dirname + '/spec/javascripts/webpack';
testWebpackConfig.output.pathinfo = true;
testWebpackConfig.output.filename = "[name].bundle.test.js";
testWebpackConfig.plugins = [
  // expose a 'qunit' global variable to any file that uses it
  new webpack.ProvidePlugin({qunit: 'qunitjs'}),
  new I18nPlugin(),
  new ClientAppsPlugin(),
  new CompiledReferencePlugin(),
  new webpack.IgnorePlugin(/\.md$/),
  new webpack.IgnorePlugin(/(CHANGELOG|LICENSE|README)$/),
  new webpack.IgnorePlugin(/package.json/),
  new webpack.DefinePlugin(jspecEnv),
];

testWebpackConfig.resolve.alias.qunit = 'qunitjs';
testWebpackConfig.resolve.root.push(__dirname + '/spec/coffeescripts');
testWebpackConfig.resolve.root.push(__dirname + '/spec/javascripts/support');
testWebpackConfig.resolve.alias["spec/jsx"] = __dirname + '/spec/javascripts/jsx';

// Some plugins use a special spec_canvas path for their specs
testWebpackConfig.module.loaders.unshift({
  test: [
    /\/spec\/coffeescripts\//,
    /\/spec_canvas\/coffeescripts\//,
    /\/spec\/javascripts\/jsx\//,
    /\/ember\/.*\/tests\//
  ],

  // Our spec files expect qunit's global `test`, `module`, `asyncTest` and `start` variables.
  // These imports loaders make it so they are avalable as local variables
  // inside of a closure, without truly making them globals.
  // We should get rid of this and just change our actual source to s/test/qunit.test/ and s/module/qunit.module/
  loaders: [
    'imports?test=>qunit.test',
    'imports?asyncTest=>qunit.asyncTest',
    'imports?start=>qunit.start',
    "qunitDependencyLoader"
  ]
});


testWebpackConfig.module.postLoaders = [{
  test: /(jsx.*(\.js$|\.jsx$)|\.coffee$|public\/javascripts\/.*\.js$)/,
  exclude: /(node_modules|spec|public\/javascripts\/(bower|client_apps|compiled|jst|jsx|translations|vendor))/,
  loader: 'istanbul-instrumenter'
}]


testWebpackConfig.module.noParse = [
  /\/sinon-1.17.2.js/,
  /\/axe.js/
]

module.exports = testWebpackConfig;
