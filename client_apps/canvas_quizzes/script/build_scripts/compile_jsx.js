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
var glob = require('glob')
var path = require('path')
var transform = require('react-tools').transform
var convertTextBlocks = require('canvas_react_i18n')

var processJSX = function(rawJSX) {
  return transform(convertTextBlocks(rawJSX))
}

module.exports = function(srcDir, destDir) {
  if (!destDir) {
    destDir = srcDir
  }

  glob.sync('**/*.js', {cwd: srcDir}).forEach(function(file) {
    var compiled, outfile

    console.log('Compiling JSX:', file)

    compiled = processJSX(fs.readFileSync(path.join(srcDir, file), 'utf8'))
    outfile = path.join(destDir, file.replace(/\.js$/, '.js'))

    fs.ensureDirSync(path.dirname(outfile))
    fs.writeFileSync(outfile, compiled)
  })
}
