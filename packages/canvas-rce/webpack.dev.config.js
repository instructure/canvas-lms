/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

const {merge} = require('webpack-merge')
const demoConfig = require('./webpack.demo.config')
const {WebpackPluginServe: Serve} = require('webpack-plugin-serve')

const serve = new Serve({
  host: 'localhost',
  port: 8080,
  static: [demoConfig.output.path],
  open: true,
  liveReload: true
})

module.exports = merge(demoConfig, {
  watch: true,
  entry: {
    demo: ['webpack-plugin-serve/client']
  },
  plugins: [serve]
})
