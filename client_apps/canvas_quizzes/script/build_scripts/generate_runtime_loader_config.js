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

/* jshint node:true */

var glob = require('glob')
var fs = require('fs')
var readJSON = require('../helpers/read_json')
var CANVAS_PACKAGE_MAP = readJSON('config/requirejs/build/map.json')
var K = require('./constants')
var PKG_NAME = K.pkgName

/**
 * Generate r.js config to pass to requirejs.config() at RUN-TIME so that the
 * app can resolve modules within the common bundle.
 *
 * @param  {String[]} commonBundle
 *         IDs of the modules that are provided by the common bundle.
 *         See ./extract_common_modules.js and ./extract_common_bundle.js
 *
 * @param  {String} appName
 *         Name of the app we're currently building and configuring for.
 *
 * @return {Object}
 *         Configuration to pass to requirejs.config() in the output file.
 */
module.exports = function generateRuntimeLoaderConfig(commonBundle, appName) {
  var config = {}

  config.map = {}

  // Mapping of libraries we're using from Canvas to the IDs Canvas actually
  // defines:
  config.map[PKG_NAME] = CANVAS_PACKAGE_MAP

  // The common config "loader" script will require a file that should be
  // resolved within the *current running app*. This allows us to define the
  // loader once, and have it work against every app's (different) config files.
  //
  // This is possible using the mapping line below, which basically says:
  //
  // """
  //   Anytime I'm requiring any module that starts with "app/" INSIDE the
  //   module named "[PKG_NAME]/config", rewrite that module by prefixing the
  //   current app's module id.
  // """
  config.map[PKG_NAME + '/config'] = {
    app: [K.pkgName, 'apps', appName].join('/')
  }

  // Tell r.js of all the modules that are contained inside the the common
  // bundle file, so that referencing any of these modules can be resolved
  // correctly.
  //
  // For example, for a PKG_NAME of "canvas_quizzes":
  //
  //     require("canvas_quizzes/core/promise");
  //
  // Will look for that module inside the file where "canvas_quizzes" is
  // located (e.g, /client_apps/canvas_quizzes.js).
  config.bundles = {}
  config.bundles[PKG_NAME] = commonBundle

  return config
}
