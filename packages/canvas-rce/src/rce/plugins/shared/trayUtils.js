/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

const MASQUERADE_SELECTOR = 'body.is-masquerading-or-student-view'

let trayHeight = null

// Adjusts the height that slide-out trays should take up based on the presence
// or absence of the masquerade bottom bar. Caches the result of this check
// forever, since we always reload the bundle when you enter/leave masquerade.
export const getTrayHeight = () => {
  if (!trayHeight) {
    const masqueradeBar = document.querySelector(MASQUERADE_SELECTOR)
    trayHeight = masqueradeBar ? 'calc(100vh - 50px)' : '100vh'
  }
  return trayHeight
}
