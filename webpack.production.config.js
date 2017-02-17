process.env.NODE_ENV = 'production'

const productionWebpackConfig = require('./frontend_build/baseWebpackConfig')
const ParallelUglifyPlugin = require('webpack-parallel-uglify-plugin')

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(
    new ParallelUglifyPlugin({
      // cacheDir, // Optional absolute path to use as a cache. If not provided, caching will not be used.
      uglifyJS: {
        compress: {
          screw_ie8: true,
          warnings: true
        },
        mangle: {
          screw_ie8: true
        },
        output: {
          comments: false,
          screw_ie8: true
        }
      },
    })
  )
}

module.exports = productionWebpackConfig
