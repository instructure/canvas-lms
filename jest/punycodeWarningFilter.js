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

// This file intercepts and filters out punycode deprecation warnings
// It works by patching the process.stderr.write method

const originalWrite = process.stderr.write

process.stderr.write = function (chunk, encoding, callback) {
  const str = typeof chunk === 'string' ? chunk : chunk.toString()

  if (str.includes('[DEP0040]') && str.includes('The `punycode` module is deprecated')) {
    if (typeof callback === 'function') {
      callback()
    }

    return true
  }

  return originalWrite.apply(this, arguments)
}
