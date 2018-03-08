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

// Helper for use with sinon.server.respondWith() to save you from:
//
//   - JSON.stringifying() the body
//   - adding JSON response Content-Type headers
//   - remembering whether headers or body go first!
//
this.xhrResponse = function(statusCode, body, headers) {
  if (!headers) {
    headers = {}
  }

  if (!headers['Content-Type']) {
    headers['Content-Type'] = 'application/json'
  }

  return [statusCode, headers, JSON.stringify(body)]
}
