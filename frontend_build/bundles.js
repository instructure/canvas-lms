/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

const glob = require('glob')

const entries = {}

const bundlesPattern = `${__dirname}/../app/{jsx,coffeescripts}/bundles/**/*.{coffee,js}`
const pluginBundlesPattern = `${__dirname}/../gems/plugins/*/app/{jsx,coffeescripts}/bundles/**/*.{coffee,js}`
const bundleNameRegexp = /\/(coffeescripts|jsx)\/bundles\/(.*).(coffee|js)/
const fileNameRegexp = /\/([^/]+)\.(coffee|js)/
const pluginNameRegexp = /plugins\/([^/]+)\/app/

const appBundles = glob.sync(bundlesPattern, [])
const pluginBundles = glob.sync(pluginBundlesPattern, [])

// these are bundles that are dependencies, and therefore should not be compiled
//  as entry points (webpack won't allow that).
// TODO: Ultimately we should move them to other directories.
const nonEntryPoints = ['modules/account_quota_settings', 'modules/content_migration_setup']

appBundles.forEach(entryFilepath => {
  const entryBundlePath = entryFilepath.replace(
    /^.*app\/(coffeescripts|jsx)\/bundles/,
    (_, dir) => `./app/${dir}/bundles`
  )
  const entryName = bundleNameRegexp.exec(entryBundlePath)[2]
  if (!nonEntryPoints.includes(entryName)) {
    entries[entryName] = entryBundlePath
  }
})

pluginBundles.forEach(entryFilepath => {
  const pluginName = pluginNameRegexp.exec(entryFilepath)[1]
  const fileName = fileNameRegexp.exec(entryFilepath)[1]
  const bundleName = `${pluginName}-${fileName}`
  entries[bundleName] = entryFilepath
})

module.exports = entries
