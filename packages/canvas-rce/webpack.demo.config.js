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

const path = require('path')
const {merge} = require('webpack-merge')
const sharedConfig = require('./webpack.shared.config')

const APP_FILE = path.join(__dirname, 'demo', 'app.js')
// I'm not sure, but I think the demo output dir is 'github-pages`
// for when it could be hosted on github as a working demo.
const OUTPUT_DIR = path.join(__dirname, 'github-pages', 'dist')

module.exports = merge(sharedConfig, {
  mode: 'development',
  devtool: 'eval-source-map',
  entry: {
    demo: [APP_FILE]
  },
  output: {
    path: OUTPUT_DIR
  }
})
