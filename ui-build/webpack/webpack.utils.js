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

const {sync} = require('glob')
const {canvasDir} = require('../params')

exports.globPlugins = function (pattern) {
  return sync(`gems/plugins/*/${pattern}`, {
    absolute: true,
    cwd: canvasDir,
  })
}

// e.g. ['foo-bar': 'gems/plugins/foo/app/coffeescripts/bundles/bar.js']
exports.getPluginBundles = function () {
  // TODO: move plugin frontend code in app/{jsx,coffeescripts}/bundles to ui/features
  const pluginBundlesPattern = `${canvasDir}/gems/plugins/*/app/{jsx,coffeescripts}/bundles/**/*.{js,jsx}`
  const fileNameRegexp = /\/([^/]+)\.jsx?/
  const pluginNameRegexp = /plugins\/([^/]+)\/app/
  const pluginBundles = sync(pluginBundlesPattern, []).map(entryFilepath => {
    const pluginName = pluginNameRegexp.exec(entryFilepath)[1]
    const fileName = fileNameRegexp.exec(entryFilepath)[1]
    const relativePath = entryFilepath.replace(/.*\/gems\/plugins/, '../gems/plugins')
    return [`${pluginName}-${fileName}`, relativePath]
  })
  return pluginBundles
}
