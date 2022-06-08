/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

const webpack = require('webpack')
const path = require('path')

module.exports = {
  module: {
    rules: [
      // this has been broken for a while and babel needs to be reconfigured for
      // it without depending on @instructure/ui-babel-preset
      {
        test: /\.jsx?$/,
        use: [{
          loader: 'babel-loader',
          options: {
            configFile: false,
          }
        }],
        include: [
          path.resolve(__dirname, 'src'),
          path.resolve(__dirname, 'demo'),
        ],
      },
      {
        test: /\.(woff(2)?|otf|ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: 'file-loader'
      }
    ]
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(process.env.NODE_ENV || 'development')
      }
    })
  ]
}
