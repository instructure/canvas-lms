/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

// This loader knows how to build a glue module that requires both the original
// unextended file from canvas, and any extensions from plugins, and builds
// a chain of calls to apply the extensions.  This is a replacement for any
// place in the app the original file is required.

function extractFileName(remainingRequest) {
  const loaderedPieces = remainingRequest.split('!')
  const unloaderedRequest = loaderedPieces[loaderedPieces.length - 1]
  return unloaderedRequest.replace(/^.*\/app\/coffeescripts\//, '')
}

module.exports = function(source) {
  throw 'Should not ever make it to the actual extensions loader because the pitching function does the work'
}

module.exports.pitch = function(remainingRequest, precedingRequest, data) {
  this.cacheable()

  const fileName = extractFileName(remainingRequest)
  const plugins = this.query.replace('?', '').split(',')
  const originalRequire = `unextended!coffeescripts/${fileName}`
  const pluginPaths = [originalRequire]
  const pluginArgs = []
  plugins.forEach((plugin, i) => {
    const pluginExtension = `${plugin}/app/coffeescripts/extensions/${fileName}`
    pluginPaths.push(pluginExtension)
    pluginArgs.push(`p${i}`)
  })

  let pluginChain = 'orig'

  let i = pluginArgs.length - 1
  while (i >= 0) {
    const pluginCall = pluginArgs[i]
    pluginChain = `${pluginCall}(${pluginChain})`
    i--
  }

  return `
    define(${JSON.stringify(pluginPaths)},function(orig, ${pluginArgs.join(',')}){
      return ${pluginChain}
    });
  `
}
