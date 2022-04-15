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

// These are used by assignments2 and courses#show to reload page when the selected
// observed user changes while persisting focus of the observer picker for a11y.
export const getHandleChangeObservedUser = () => {
  let prevObservedUser
  return newObservedUser => {
    if (!prevObservedUser) {
      prevObservedUser = newObservedUser
    } else if (newObservedUser !== prevObservedUser) {
      sessionStorage.setItem('autoFocusObserverPicker', true)
      window.location.reload()
    }
  }
}

export const autoFocusObserverPicker = () => {
  if (sessionStorage.getItem('autoFocusObserverPicker')) {
    sessionStorage.removeItem('autoFocusObserverPicker')
    return true
  }
  return false
}
