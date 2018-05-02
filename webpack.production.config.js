process.env.NODE_ENV = 'production'

const productionWebpackConfig = require('./frontend_build/baseWebpackConfig')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(
    new UglifyJsPlugin({
      sourceMap: true,
      parallel: true,
      uglifyOptions: {
        compress: {
          sequences: false // prevents it from combining a bunch of statments with ","s so it is easier to set breakpoints
        },
        ecma: 5,
        output: {
          comments: false,
          semicolons: false, // not because of the holy war but because it prevents everything being on one line and is easer to read in browser
        },
        safari10: true,
      }
    })
  )
}

module.exports = productionWebpackConfig
