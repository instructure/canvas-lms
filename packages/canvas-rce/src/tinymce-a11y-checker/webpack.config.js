const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: {
    demo: './src/demo.js'
  },
  module: {
    rules: [
      { test: /\.js$/, exclude: /node_modules/, use: 'babel-loader' }
    ]
  },
  devtool: 'inline-source-map',
  devServer: {
    contentBase: './demo'
  },
  plugins: [
    new HtmlWebpackPlugin({
      title: 'Accessibility Checker Demo',
      chunks: ['demo']
    })
  ],
  output: {
    filename: '[name].bundle.js',
    path: path.resolve(__dirname, 'demo')
  }
}