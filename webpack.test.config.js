var webpack = require("webpack");
var I18nPlugin = require("./frontend_build/i18nPlugin");
var ClientAppsPlugin = require("./frontend_build/clientAppPlugin");
var CompiledReferencePlugin = require("./frontend_build/CompiledReferencePlugin");
var ShimmedAmdPlugin = require("./frontend_build/shimmedAmdPlugin");

var baseWebpackConfig = require("./frontend_build/baseWebpackConfig");
var testWebpackConfig = baseWebpackConfig;

testWebpackConfig.entry = {
  'WebpackedSpecs': "./spec/javascripts/webpack_spec_index.js"
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
testWebpackConfig.resolve.modulesDirectories.push('spec/coffeescripts');
testWebpackConfig.resolve.modulesDirectories.push('spec/javascripts/support');
testWebpackConfig.module.loaders.push({
  test: /\/spec\/coffeescripts\//,
  loaders: ["qunitDependencyLoader"]
});
testWebpackConfig.module.noParse = [
  /\/sinon-1.17.2.js/
]

module.exports = testWebpackConfig;
