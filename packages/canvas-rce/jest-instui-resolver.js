/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

// InstUI v11's CJS builds use directory subpath imports
// (e.g. @instructure/ui-form-field/lib/FormField resolves to a directory).
// Jest's default resolver returns the directory path, causing EISDIR when it
// tries to read the file. This resolver appends /index.js in that case.
const path = require('path')
const fs = require('fs')

module.exports = (request, options) => {
  try {
    const resolved = options.defaultResolver(request, options)
    // If the resolved path is a directory, append /index.js
    if (resolved && fs.existsSync(resolved) && fs.statSync(resolved).isDirectory()) {
      const indexPath = path.join(resolved, 'index.js')
      if (fs.existsSync(indexPath)) return indexPath
    }
    return resolved
  } catch (err) {
    // Also handle MODULE_NOT_FOUND for @instructure lib/ directory imports
    if (err?.code === 'MODULE_NOT_FOUND' && request.includes('@instructure/')) {
      const m = request.match(/^@instructure\/(ui-[^/]+)\/lib\/(.+)$/)
      if (m) {
        const dir = path.join(
          path.dirname(options.rootDir),
          'node_modules/@instructure',
          m[1],
          'lib',
          m[2],
        )
        if (fs.existsSync(dir) && fs.statSync(dir).isDirectory()) {
          const idx = path.join(dir, 'index.js')
          if (fs.existsSync(idx)) return idx
        }
      }
    }
    throw err
  }
}
