/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export default function buildReducer(handlers, initialState) {
  return function reducer(state, action) {
    if (!state) {
      return initialState
    }

    if (handlers[action.type]) {
      try {
        // If the current map of handlers includes this action type, return the
        // result of the function assigned to the action type.
        const handler = handlers[action.type]
        return handler(state, action)
      } catch (e) {
        // If the handling function throws an error, it must be caught.
        // Otherwise, the application can crash without a chance to recover.
        console.error(e) // eslint-disable-line no-console
      }
    }

    return state
  }
}
