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

import files from '../files'
import * as actions from '../../actions/files'

describe('Files reducer', () => {
  let state

  beforeEach(() => {
    state = {}
  })

  it('does not modify the state if for unknown actions', () => {
    expect(files(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('ADD_FILE', () => {
    let action

    beforeEach(() => {
      action = {
        type: actions.ADD_FILE,
        id: 1,
        name: 'Foo',
        fileType: 'text/plain',
        url: '/files/1',
        embed: {type: 'scribd'},
      }
    })

    it('adds a new property to files keyed by id from action', () => {
      expect(files(state, action)[action.id]).toBeTruthy()
    })

    it('sets id from action', () => {
      expect(files(state, action)[action.id].id).toBe(action.id)
    })

    it('sets name from action', () => {
      expect(files(state, action)[action.id].name).toBe(action.name)
    })

    it('sets type from action fileType', () => {
      expect(files(state, action)[action.id].type).toBe(action.fileType)
    })

    it('sets url from action', () => {
      expect(files(state, action)[action.id].url).toBe(action.url)
    })

    it('sets embed from action', () => {
      expect(files(state, action)[action.id].embed).toBe(action.embed)
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(files(state, action).foo).toBe(state.foo)
    })
  })
})
