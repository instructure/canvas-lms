module.exports = {
  entry: "./example/main.js",
  output: {
    library: 'TokenInput',
    libraryTarget: 'umd'
  },

  externals: [
    {
      "react": {
        root: "React",
        commonjs2: "react",
        commonjs: "react",
        amd: "react"
      }
    }
  ],
  debug: true,
  devtool: '#source-map',
  module: {
    loaders: [
      {test: /\.js$/, loader: 'babel'}
    ]
  }
};
