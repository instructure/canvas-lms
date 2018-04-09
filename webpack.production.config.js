process.env.NODE_ENV = 'production'

const productionWebpackConfig = require('./frontend_build/baseWebpackConfig')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(
    new UglifyJsPlugin({
      sourceMap: true,
      parallel: true,
      uglifyOptions: {
        ecma: 5,
        output: {
          comments: false,
        },
        safari10: true,
      }
    })
  )
}

module.exports = productionWebpackConfig
