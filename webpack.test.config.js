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
testWebpackConfig.output.filename = "[name].bundle.test.js";
testWebpackConfig.plugins = [
  new I18nPlugin(),
  new ShimmedAmdPlugin(),
  new ClientAppsPlugin(),
  new CompiledReferencePlugin()
];

testWebpackConfig.resolve.alias.qunit = "qunitjs/qunit/qunit.js";
testWebpackConfig.module.loaders.push({
  test: /\/spec\/coffeescripts\//,
  loaders: ["qunitDependencyLoader"]
});

module.exports = testWebpackConfig;
