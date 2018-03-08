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

var fs = require('fs-extra')
var path = require('path')
var K = require('./constants')
var PKG_NAME = K.pkgName
var APP_NAMES = K.appNames
var basePath = path.join(K.root, 'tmp', 'dist')
var destPath = path.join(K.root, 'dist')

module.exports = function() {
  // Each app module will be placed under /dist/PKG_NAME/apps/APP_NAME.js.
  //
  // The filepath matches the convenience module we've defined at build-time (
  // the one that does not contain "/main" in the module id).
  var files = APP_NAMES.map(function(appName) {
    return {
      src: path.join(basePath, PKG_NAME, 'apps', appName, 'main.js'),
      dest: path.join(destPath, PKG_NAME, 'apps', appName + '.js')
    }
  })

  // The common bundle, which is named by the name of the package and not
  // inside /apps:
  files.unshift({
    src: path.join(basePath, PKG_NAME + '.js'),
    dest: path.join(destPath, PKG_NAME + '.js')
  })

  files.forEach(function(descriptor, index) {
    var src = descriptor.src
    var dest = descriptor.dest

    if (!fs.existsSync(src)) {
      console.error("Expected built bundle to be found at '" + src + "' but was not.")
      process.exit(1)
    }

    console.log('Asset [' + (index + 1) + ']:')

    fs.ensureDirSync(path.dirname(dest))
    fs.copySync(src, dest)

    console.log('\t' + dest)
  })
}
