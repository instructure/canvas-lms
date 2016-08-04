import 'babel-polyfill'
var webpack = require("webpack");
var I18nPlugin = require("./frontend_build/i18nPlugin");
var ClientAppsPlugin = require("./frontend_build/clientAppPlugin");
var CompiledReferencePlugin = require("./frontend_build/CompiledReferencePlugin");
var ShimmedAmdPlugin = require("./frontend_build/shimmedAmdPlugin");

var baseWebpackConfig = require("./frontend_build/baseWebpackConfig");
var testWebpackConfig = baseWebpackConfig;

// the ember specs don't play nice with the rest,
// so we run them in totally seperate bundles
if(process.env.WEBPACK_TEST_BUNDLE == 'ember'){
  testWebpackConfig.entry = {
    'WebpackedEmberSpecs': "./spec/javascripts/webpack_ember_spec_index.js"
  }
}else {
  testWebpackConfig.entry = {
    'WebpackedSpecs': "./spec/javascripts/webpack_spec_index.js"
  }
}

testWebpackConfig.devtool = undefined;
testWebpackConfig.output.path = __dirname + '/spec/javascripts/webpack';
testWebpackConfig.output.pathinfo = true;
testWebpackConfig.output.filename = "[name].bundle.test.js";
testWebpackConfig.plugins = [
  new I18nPlugin(),
  new ShimmedAmdPlugin(),
  new ClientAppsPlugin(),
  new CompiledReferencePlugin(),
  new webpack.IgnorePlugin(/\.md$/),
  new webpack.IgnorePlugin(/(CHANGELOG|LICENSE|README)$/),
  new webpack.IgnorePlugin(/package.json/)
];

testWebpackConfig.resolve.alias.qunit = "qunitjs/qunit/qunit.js";
testWebpackConfig.resolve.root.push(__dirname + '/spec/coffeescripts');
testWebpackConfig.resolve.root.push(__dirname + '/spec/javascripts/support');

testWebpackConfig.module.loaders.push({
  test: /\/spec\/coffeescripts\//,
  loaders: ["qunitDependencyLoader"]
});

// Some plugins use a special spec_canvas path for their specs
testWebpackConfig.module.loaders.push({
  test: /\/spec_canvas\/coffeescripts\//,
  loaders: [
    'qunitDependencyLoader'
  ]
});

testWebpackConfig.module.loaders.push({
  test: /\/spec\/javascripts\/jsx\//,
  loaders: ["qunitJsxDependencyLoader"]
});

testWebpackConfig.module.loaders.push({
  test: /\/ember\/.*\/tests\//,
  loaders: ["qunitDependencyLoader"]
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
