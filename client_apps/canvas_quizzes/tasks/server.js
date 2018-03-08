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

module.exports = {
  description: 'Serve the application using a local Connect server.',
  runner: function(grunt, appName) {
    var availableApps = grunt.file
      .expand('apps/*')
      .filter(function(name) {
        return name !== 'apps/common'
      })
      .map(function(name) {
        return name.substr(5)
      })

    if (availableApps.indexOf(appName) === -1) {
      grunt.fail.fatal(
        'You must specify an app name to serve.\n' +
          'Available apps are: ' +
          JSON.stringify(availableApps) +
          '\n' +
          'For example: `grunt server:' +
          availableApps[0] +
          '`'
      )
    }

    grunt.config.set('currentApp', appName)
    grunt.task.run([
      'development',
      'configureRewriteRules',
      'configureProxies:www',
      'connect:www',
      'connect:tests',
      'connect:docs',
      'watch'
    ])
  }
}
