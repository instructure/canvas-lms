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

var K = require('./constants')
var config

/**
 * Extract the r.js config we use in development, which includes paths and maps
 * that we will need for building.
 *
 * Note that that script expects a browser/rjs runtime environment as it calls
 * requirejs.config() so we have to hack around it.
 *
 * See /config/requirejs/development.js
 *
 * @return {Object}
 *         Object passed to requirejs.config() in that file.
 */
module.exports = function() {
  var noConflict = global.requirejs

  if (config) {
    // cache
    return config
  }

  global.requirejs = {
    config: function(inConfig) {
      config = inConfig
    }
  }

  K.require('config/requirejs/development')

  global.requirejs = noConflict

  return config
}
