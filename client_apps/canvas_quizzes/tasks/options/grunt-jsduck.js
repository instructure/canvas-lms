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

var grunt = require('grunt')

module.exports = {
  main: {
    src: ['apps/*/js/**/*.js', 'tmp/compiled_jsx/**/*.js'],
    dest: 'doc/api',
    options: {
      title: "<%= grunt.config.get('pkg.title') %> Reference",
      'builtin-classes': false,
      color: true,
      'no-source': false,
      tests: true,
      processes: 2,
      warnings: [],
      guides: 'doc/guides.json',
      'head-html': 'doc/head.html',
      tags: grunt.file.expand('doc/ext/jsduck/tags/*.rb'),
      external: [
        'React',
        'React.Component',
        'React.Class',
        'RSVP',
        'RSVP.Promise',
        'jQuery',
        'QTip',
        'qTip',
        'Promise'
      ]
    }
  }
}
