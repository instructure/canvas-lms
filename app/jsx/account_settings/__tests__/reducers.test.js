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

import {cspEnabled} from '../reducers'
import {SET_CSP_ENABLED, SET_CSP_ENABLED_OPTIMISTIC} from '../actions'

describe('cspEnabled', () => {
  const testMatrix = [
    [{type: SET_CSP_ENABLED, payload: true}, undefined, true],
    [{type: SET_CSP_ENABLED_OPTIMISTIC, payload: false}, undefined, false]
  ]
  it.each(testMatrix)(
    'with %p action and %p value the cspEnabled state becomes %p',
    (action, initialState, expectedState) => {
      expect(cspEnabled(initialState, action)).toEqual(expectedState)
    }
  )
})
