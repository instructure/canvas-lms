const path = require('path');

module.exports = {
  entry: './src/demo.js',

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'canvas-planner.js',
  },
  plugins: require('@instructure/ui-presets/webpack/plugins'),
  module: {
    rules: require('@instructure/ui-presets/webpack/module/rules')
  },
  resolveLoader: require('@instructure/ui-presets/webpack/resolveLoader'),

  devtool: 'cheap-module-source-map',

  devServer: {
    disableHostCheck: true,
    proxy: {
      '**': {
        target: 'http://localhost:3004',
        changeOrigin: true,
        pathRewrite: { '^/api/v1' : '' }
      }
    },
    contentBase: path.join(__dirname, 'public')
  }
};
