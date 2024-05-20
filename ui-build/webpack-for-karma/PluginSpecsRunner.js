/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const glob = require('glob')
const fs = require('fs')

class PluginSpecsRunner {
  constructor({pattern, outfile}) {
    this.pattern = pattern
    this.outfile = outfile
  }

  apply(compiler) {
    compiler.hooks.beforeCompile.tapAsync('PluginSpecsRunner', (_, callback) => {
      glob(this.pattern, {absolute: true}, (e, files) => {
        if (e) {
          return callback(e)
        }

        fs.writeFile(this.outfile, files.map(x => `require("${x}")`).join('\n'), 'utf8', callback)
      })
    })
  }
}

module.exports = PluginSpecsRunner
