process.env.NODE_ENV = 'production'

const productionWebpackConfig = require('./frontend_build/baseWebpackConfig')
const ParallelUglifyPlugin = require('webpack-parallel-uglify-plugin')

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(
    new ParallelUglifyPlugin({
      sourceMap: true,
      uglifyJS: {
        ie8: false
      }
    })
  )
}

module.exports = productionWebpackConfig
