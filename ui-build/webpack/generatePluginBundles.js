/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

const fs = require('fs')
const {getPluginBundles} = require('./webpack.utils')

// generates file with functions that dynamically import each plugin bundle
fs.writeFileSync(
  './node_modules/plugin-bundles-generated.js',
  `
const pluginBundles = {
${getPluginBundles()
  .map(
    ([entryName, entryBundlePath]) =>
      `  "${entryName}": () => import(/* webpackChunkName: "${entryName}" */ "${entryBundlePath}"),`
  )
  .join('\n')
  .slice(0, -1)}
}
export default pluginBundles
`
)
