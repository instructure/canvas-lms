/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

var path = require('path')
var glob = require('glob')
var readJSON = require('../helpers/read_json')

var K = {}
var pkg = readJSON('package.json')
var root = path.join(__dirname, '..', '..')

K.root = root
K.pkgName = pkg.name

K.appNames = glob
  .sync('*/js/main.js', {cwd: path.join(root, 'apps')})
  .map(function(file) {
    return file.split('/')[0]
  })
  .filter(function(appName) {
    return appName !== 'common'
  })

K.bundledDependencies = pkg.requirejs.bundledDependencies
K.commonRoot = 'apps/common'

K.require = function(relativePath) {
  return require(path.join(root, relativePath))
}

module.exports = K
