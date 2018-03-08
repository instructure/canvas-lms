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

var shell = require('shelljs')
var fs = require('fs')
var path = require('path')
var glob = require('glob')

module.exports = {
  description: 'Generate the notification bundle.',
  runner: function(grunt, target) {
    var root = grunt.paths.root
    var outPath = path.join(root, 'src/js/bundles/notifications.js')
    var BUNDLE_PATH = path.join(root, 'src/js/notifications')
    var scripts = glob.sync('*.js', {cwd: BUNDLE_PATH}).reduce(function(set, script) {
      return set.concat(script.replace(/\.js$/, ''))
    }, [])

    var template =
      '/** WARNING: AUTO-GENERATED, DO NOT EDIT */\n' +
      'define([' +
      scripts
        .map(function(script) {
          return '"../notifications/' + script + '"'
        })
        .join(',\n') +
      '], function() {\nreturn [].slice.call(arguments);\n});'

    fs.writeFileSync(outPath, template)

    console.log('Notification bundle written to ' + outPath)
  }
}
