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

import reducer from '../session'
import {RECEIVE_SESSION} from '../../actions/session'

describe('Session reducer', () => {
  describe('RECEIVE_SESSION action', () => {
    it('merges action data with existing state', () => {
      const state = {a: 1, b: 2}
      const ret = reducer(state, {
        type: RECEIVE_SESSION,
        data: {b: 3, c: 4},
      })
      expect(ret).toEqual({a: 1, b: 3, c: 4})
    })
  })

  it('returns the original state if called with other action', () => {
    const state = {}
    const ret = reducer(state, {type: 'SOME_OTHER_ACTION'})
    expect(ret).toBe(state)
  })
})
