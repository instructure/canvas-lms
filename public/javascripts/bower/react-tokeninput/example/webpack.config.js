module.exports = {
  entry: {
    './example/bundle': './example/main.js'
  },
  output: {
    filename: "[name].js"
  },
  debug: true,
  devtool: '#inline-source-map',
  module: {
    loaders: [
      { test: /\.js$/, exclude: /node_modules/, loader: 'babel-loader?experimental'}
    ]
  }
};

