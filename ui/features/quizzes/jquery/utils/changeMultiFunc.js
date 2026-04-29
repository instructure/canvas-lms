/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'

/**
 * Checks if a change event handler with the name 'changeMultiFunc' is bound to the given element
 * @param {jQuery} $questionContent - jQuery element to check for bound events
 * @returns {boolean} - true if changeMultiFunc is bound, false otherwise
 */
export function isChangeMultiFuncBound($questionContent) {
  let ret = false
  const events = $._data($questionContent[0], 'events')
  if (events && events.change) {
    events.change.forEach(event => {
      if (event.handler.origFuncNm === 'changeMultiFunc') {
        ret = true
      }
    })
  }
  return ret
}
