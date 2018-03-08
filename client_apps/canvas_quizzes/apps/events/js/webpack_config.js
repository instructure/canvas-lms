/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

var config = require('./config/environments/production')
var callbacks = []
var loaded

if (!config) {
  config = {}
}

config.onLoad = function(callback) {
  if (loaded) {
    callback()
  } else {
    callbacks.push(callback)
  }
}

if (process.env.NODE_ENV !== 'production') {
  var extend = require('lodash').extend
  var onLoad = function() {
    console.log('\tLoaded', process.env.NODE_ENV, 'config.')
    loaded = true

    while (callbacks.length) {
      callbacks.shift()()
    }
  }

  console.log('Environment:', process.env.NODE_ENV)

  var onEnvSpecificConfigLoaded = function(envSpecificConfig) {
    extend(config, envSpecificConfig)
    onLoad()
  }
  if (process.env.NODE_ENV === 'test') {
    require(['./config/environments/test'], onEnvSpecificConfigLoaded)
  } else {
    require(['./config/environments/development'], onEnvSpecificConfigLoaded)
  }
}

module.exports = config
