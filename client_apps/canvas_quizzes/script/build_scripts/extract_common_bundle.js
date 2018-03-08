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
var readJSON = require('../helpers/read_json')
var K = require('./constants')

/**
 * Prepare a set of module IDs for use inside the "bundles" r.js config hash.
 * The module IDs need to be stripped of any loader plugins (like jsx!) because
 * at the time the bundle is used, the files will be compiled and the loader
 * will not be available in the first place.
 *
 * This is needed for both run-time and build-time configs (which gets exposed
 * to Canvas.)
 *
 * @param  {String[]} commonModules
 *         IDs of the modules that are provided by the common bundle.
 *         See ./extract_common_modules.js for getting this array.
 *
 * @return {String[]}
 */
module.exports = function(commonModules) {
  return commonModules.map(function(moduleId) {
    // Since we're excluding the JSX plugin from the build, we need to discard
    // the loader plugin prefix from the module identifiers:
    return moduleId.replace('jsx!', '')
  })
}
