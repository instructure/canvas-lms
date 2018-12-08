/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

process.env.NODE_ENV = 'production'

const UglifyJsPlugin = require('uglifyjs-webpack-plugin')
const productionWebpackConfig = require('./frontend_build/baseWebpackConfig')

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(
    new UglifyJsPlugin({
      sourceMap: true,
      parallel: true,
      uglifyOptions: {
        compress: {
          sequences: false, // prevents it from combining a bunch of statments with ","s so it is easier to set breakpoints
          reduce_funcs: false // works around this bug: https://github.com/facebook/react/issues/13987#issuecomment-437100945
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
