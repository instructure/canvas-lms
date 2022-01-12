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

const webpack = require('./ui-build/webpack')

// since istanbul-instrumenter-loader adds so much overhead, only use it when generating crystalball map
if (process.env.CRYSTALBALL_MAP === '1') {
  const path = require('path')
  const {canvasDir} = require('./ui-build/params')

  webpack.module.rules.unshift({
    test: /\.(js|ts|tsx)$/,
    include: [
      path.resolve(canvasDir, 'ui'),
      path.resolve(canvasDir, 'packages/jquery-kyle-menu'),
      path.resolve(canvasDir, 'packages/jquery-sticky'),
      path.resolve(canvasDir, 'packages/jquery-popover'),
      path.resolve(canvasDir, 'packages/jquery-selectmenu'),
      path.resolve(canvasDir, 'packages/mathml'),
      path.resolve(canvasDir, 'packages/persistent-array'),
      path.resolve(canvasDir, 'packages/slickgrid'),
      path.resolve(canvasDir, 'packages/with-breakpoints'),
      path.resolve(canvasDir, 'spec/javascripts/jsx'),
      path.resolve(canvasDir, 'spec/coffeescripts'),
      /gems\/plugins\/.*\/app\/(jsx|coffeescripts)\//
    ],
    exclude: [/test\//, /spec/],
    use: {
      loader: 'istanbul-instrumenter-loader',
      options: {esModules: true, produceSourceMap: true}
    },
    enforce: 'post'
  })
}

module.exports = webpack
