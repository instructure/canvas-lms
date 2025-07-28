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

import collection from '../collection'
import * as actions from '../../actions/data'

describe('Collection reducer', () => {
  let state

  beforeEach(() => {
    state = {}
  })

  it('does not modify the state if for unknown actions', () => {
    expect(collection(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('REQUEST_PAGE', () => {
    const action = {
      type: actions.REQUEST_PAGE,
      cancel() {},
    }

    it('sets the loading flag and cancel function', () => {
      expect(collection(state, action).isLoading).toBe(true)
      expect(typeof collection(state, action).cancel).toBe('function')
    })

    it('preserves existing state', () => {
      state.arbitrary = 'data'
      expect(collection(state, action).arbitrary).toBe('data')
    })
  })

  describe('FAIL_PAGE', () => {
    let action

    beforeEach(() => {
      action = {
        type: actions.FAIL_PAGE,
        error: 'somethingBad',
      }
      state.bookmark = 'someBookmark'
      state.links = []
    })

    it('deactivates loading', () => {
      state.isLoading = true
      expect(collection(state, action).isLoading).toBe(false)
    })

    it('includes the error in state', () => {
      expect(collection(state, action).error).toBe('somethingBad')
    })

    it('blanks the bookmark if there are no links', () => {
      expect(collection(state, action).bookmark).toBe(null)
    })

    it('leaves the bookmark when links are present', () => {
      state.links = [{}, {}, {}]
      expect(collection(state, action).bookmark).toBe('someBookmark')
    })
  })
})
