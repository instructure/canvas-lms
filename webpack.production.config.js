const webpack = require('webpack');
const productionWebpackConfig = require('./frontend_build/baseWebpackConfig');

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(new webpack.optimize.UglifyJsPlugin({
    compress: {
      screw_ie8: true,
      warnings: true
    },
    mangle: {
      screw_ie8: true
    },
    output: {
      comments: false,
      screw_ie8: true
    }
  }));
}

module.exports = productionWebpackConfig;
