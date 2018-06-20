const path = require("path")

module.exports = {
  entry: {
    demo: "./src/demo.js"
  },
  module: {
    rules: [{ test: /\.js$/, exclude: /node_modules/, use: "babel-loader" }]
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
