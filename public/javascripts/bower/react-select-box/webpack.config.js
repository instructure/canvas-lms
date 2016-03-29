module.exports = {
  entry: "./example/main.js",
  output: {
    library: 'ReactSelectBox',
    libraryTarget: 'umd'
  },

  externals: {
    react: 'react',
    'react/addons': 'react'
  },
  debug: true,
  devtool: '#source-map',
  module: {
    loaders: [
      {test: /\.js$/, loader: 'jsx-loader'}
    ]
  }
};
