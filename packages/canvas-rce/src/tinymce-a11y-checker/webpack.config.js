const path = require("path")

module.exports = {
  entry: {
    demo: "./src/demo.js"
  },
  module: {
    rules: [{ test: /\.js$/, exclude: /node_modules/, use: "babel-loader" }],
    noParse: [
      /i18nliner\/dist\/lib\/i18nliner/ // i18nLiner has a `require('fs')` that it doesn't actually need, ignore it.
    ],
  },
  devtool: "inline-source-map",
  devServer: {
    contentBase: "./demo"
  },
  mode: "development",
  output: {
    filename: "[name].bundle.js",
    path: path.resolve(__dirname, "demo")
  }
}
