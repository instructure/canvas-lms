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

var glob = require('glob')
var K = require('./constants')
var commonModules

/**
 * Go through all the files within the common app (/apps/common/js) and generate
 * a list of the modules that will be provided by the built bundle.
 *
 * This list will include both .js and .jsx sources.
 *
 * @return {String[]}
 *         The list of module IDs *including* any loader plugin prefixes, like
 *         `jsx!`.
 */
module.exports = function() {
  if (commonModules) {
    // cache
    return commonModules
  }

  var PKG_NAME = K.pkgName
  var COMMON_ROOT = K.commonRoot + '/js'

  commonModules = ['js', 'jsx']
    // Find all the source files in the common bundle and extract their names
    // without the extensions (i.e, module ids):
    .reduce(function(modules, ext) {
      var pattern = '**/*.' + ext
      var extStripper = new RegExp('\\.' + ext + '$')
      var prefix = ext === 'jsx' ? 'jsx!' : ''

      return glob
        .sync(pattern, {cwd: COMMON_ROOT})
        .map(function(file) {
          if (!file.length) {
            return ''
          }

          return prefix + file.replace(extStripper, '')
        })
        .concat(modules)
    }, [])

    // Prefix all common modules with the package's name, e.g:
    // given "canvas_quizzes" for a package name, and "core/promise" as a module
    // id, we get: "canvas_quizzes/core/promise"
    //
    // This is because app modules reference the common modules by specifying
    // the package name as a prefix.
    .map(function prefixByPackageName(moduleId) {
      if (moduleId.substr(0, 4) === 'jsx!') {
        return moduleId.replace('jsx!', 'jsx!' + PKG_NAME + '/')
      } else {
        return [PKG_NAME, moduleId].join('/')
      }
    })

    // Finally, we need to also mark the 3rd-party packages that we're bundling
    // in the common bundle (e.g, RSVP, qTip, whatever).
    //
    // Those libraries are defined in package.json under the custom
    // "requirejs.bundledDependencies" key.
    //
    // See package.json for those dependencies.
    .concat(K.bundledDependencies)

  return commonModules
}
