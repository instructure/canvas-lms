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

import flickr from '../flickr'
import * as actions from '../../actions/flickr'

describe('Flickr reducer', () => {
  let state
  let action

  beforeEach(() => {
    state = {}
  })

  it('does not modify the state if for unknown actions', () => {
    expect(flickr(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('START_FLICKR_SEARCH', () => {
    beforeEach(() => {
      action = {
        type: actions.START_FLICKR_SEARCH,
        term: 'chess',
      }
    })

    it('sets searching to true', () => {
      expect(flickr(state, action).searching).toBe(true)
    })

    it('sets term from action', () => {
      expect(flickr(state, action).searchTerm).toBe('chess')
    })
  })

  describe('RECEIVE_FLICKR_RESULTS', () => {
    beforeEach(() => {
      action = {
        type: actions.RECEIVE_FLICKR_RESULTS,
        results: [1, 2, 3],
      }
    })

    it('turns searching off', () => {
      expect(flickr(state, action).searching).toBe(false)
    })

    it('passes results through for display', () => {
      expect(flickr(state, action).searchResults).toHaveLength(3)
    })
  })

  describe('FAIL_FLICKR_SEARCH', () => {
    beforeEach(() => {
      action = {
        type: actions.FAIL_FLICKR_SEARCH,
        results: [1, 2, 3],
      }
      state.formExpanded = true
      state.searchTerm = 'chess'
    })

    it('disables searching flag', () => {
      expect(flickr(state, action).searching).toBe(false)
    })

    it('blanks the search term', () => {
      expect(flickr(state, action).searchTerm).toBe('')
    })

    it('empties the search results', () => {
      expect(flickr(state, action).searchResults).toHaveLength(0)
    })

    it('leaves the form state as it is', () => {
      expect(flickr(state, action).formExpanded).toBe(state.formExpanded)
    })
  })

  describe('TOGGLE_FLICKR_FORM', () => {
    beforeEach(() => {
      action = {type: actions.TOGGLE_FLICKR_FORM}
      state.formExpanded = true
    })

    it('reverses current state', () => {
      expect(flickr(state, action).formExpanded).toBe(!state.formExpanded)
    })

    it('goes back and forth for each invocation', () => {
      state.formExpanded = false
      expect(flickr(state, action).formExpanded).toBe(true)
    })
  })
})
