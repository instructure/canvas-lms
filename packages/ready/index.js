/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/**
 * A list of functions to be called when the document is ready.
 * @type {Function[]}
 */
let fns = []

/**
 * Reference to the document object if it exists.
 * @type {Document | null}
 */
const doc = typeof document === 'object' && document

/**
 * Indicates if the document has already loaded or not.
 * @type {boolean}
 */
let loaded = !doc || /^loaded|^i|^c/.test(doc.readyState)

/**
 * Runs all listeners that are waiting for the document to be ready.
 */
function runAllReadyListeners() {
  doc.removeEventListener('DOMContentLoaded', runAllReadyListeners)
  loaded = true
  fns.forEach(fn => fn())
  fns = []
}

if (!loaded) {
  doc.addEventListener('DOMContentLoaded', runAllReadyListeners)
}

/**
 * Calls the provided function if the document is already ready,
 * else adds the function to the list to be called when the document is ready.
 *
 * @param {Function} fn - The function to be executed.
 */
module.exports = function ready(fn) {
  loaded ? fn() : fns.push(fn)
}
