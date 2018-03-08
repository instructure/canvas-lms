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
  options: {
    spawn: false
  },

  css: {
    files: '{apps/*/css,vendor/css}/**/*.{scss,css}',
    tasks: ['compile_css'],
    options: {
      spawn: true
    }
  },

  compiled_css: {
    files: 'dist/*.css',
    tasks: ['noop'],
    options: {
      livereload: {
        port: 9224
      }
    }
  },

  tests: {
    files: ['apps/*/{js,test}/**/*.j{s,sx}', 'tasks/*.js', 'vendor/packages/**/*.js'],
    tasks: ["jasmine:<%= grunt.config.get('currentApp') %>"]
  }
}
