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

import folder from '../folder'
import * as actions from '../../actions/files'

describe('Folder sidebar reducer', () => {
  let state

  beforeEach(() => {
    state = {}
  })

  it('does not modify the state if for unknown actions', () => {
    expect(folder(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('ADD_FOLDER', () => {
    let action

    beforeEach(() => {
      action = {
        type: actions.ADD_FOLDER,
        id: 1,
        name: 'Foo',
        filesUrl: '/files/1',
        foldersUrl: '/folders/1',
      }
    })

    it('sets id from action', () => {
      expect(folder(state, action).id).toBe(action.id)
    })

    it('sets name from action', () => {
      expect(folder(state, action).name).toBe(action.name)
    })

    it('sets filesUrl from action', () => {
      expect(folder(state, action).filesUrl).toBe(action.filesUrl)
    })

    it('sets foldersUrl from action', () => {
      expect(folder(state, action).foldersUrl).toBe(action.foldersUrl)
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(folder(state, action).foo).toBe(state.foo)
    })
  })

  describe('RECEIVE_FILES', () => {
    let action

    beforeEach(() => {
      Object.assign(state, {
        fileIds: [1],
        loadingCount: 1,
      })
      action = {
        type: actions.RECEIVE_FILES,
        fileIds: [2, 3, 4],
      }
    })

    it('decrements loadingCount', () => {
      expect(folder(state, action).loadingCount).toBe(state.loadingCount - 1)
    })

    it('sets loading to true if next loadingCount is not 0', () => {
      state.loadingCount = 2
      state.loading = false
      expect(folder(state, action).loading).toBe(true)
    })

    it('sets loading to false if next loadingCount is 0', () => {
      state.loadingCount = 1
      state.loading = true
      expect(folder(state, action).loading).toBe(false)
    })

    it('adds fileIds from action to existing fileIds', () => {
      expect(folder(state, action).fileIds).toEqual([1, 2, 3, 4])
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(folder(state, action).foo).toBe(state.foo)
    })
  })

  describe('RECEIVE_SUBFOLDERS', () => {
    let action

    beforeEach(() => {
      Object.assign(state, {
        folderIds: [1],
        loadingCount: 1,
      })
      action = {
        type: actions.RECEIVE_SUBFOLDERS,
        folderIds: [2, 3, 4],
      }
    })

    it('decrements loadingCount', () => {
      expect(folder(state, action).loadingCount).toBe(state.loadingCount - 1)
    })

    it('sets loading to true if next loadingCount is not 0', () => {
      state.loadingCount = 2
      state.loading = false
      expect(folder(state, action).loading).toBe(true)
    })

    it('sets loading to false if next loadingCount is 0', () => {
      state.loadingCount = 1
      state.loading = true
      expect(folder(state, action).loading).toBe(false)
    })

    it('adds folderIds from action to existing folderIds', () => {
      expect(folder(state, action).folderIds).toEqual([1, 2, 3, 4])
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(folder(state, action).foo).toBe(state.foo)
    })
  })

  describe('REQUEST_FILES', () => {
    let action

    beforeEach(() => {
      Object.assign(state, {
        loadingCount: 1,
      })
      action = {
        type: actions.REQUEST_FILES,
      }
    })

    it('sets requested to true', () => {
      expect(folder(state, action).requested).toBe(true)
    })

    it('increments loadingCount', () => {
      expect(folder(state, action).loadingCount).toBe(state.loadingCount + 1)
    })

    it('sets loading to true if next loadingCount is not 0', () => {
      state.loadingCount = 0
      state.loading = false
      expect(folder(state, action).loading).toBe(true)
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(folder(state, action).foo).toBe(state.foo)
    })
  })

  describe('REQUEST_SUBFOLDERS', () => {
    let action

    beforeEach(() => {
      Object.assign(state, {
        loadingCount: 1,
      })
      action = {
        type: actions.REQUEST_SUBFOLDERS,
      }
    })

    it('sets requested to true', () => {
      expect(folder(state, action).requested).toBe(true)
    })

    it('increments loadingCount', () => {
      expect(folder(state, action).loadingCount).toBe(state.loadingCount + 1)
    })

    it('sets loading to true if next loadingCount is not 0', () => {
      state.loadingCount = 0
      state.loading = false
      expect(folder(state, action).loading).toBe(true)
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(folder(state, action).foo).toBe(state.foo)
    })
  })

  describe('TOGGLE', () => {
    let action

    beforeEach(() => {
      action = {
        type: actions.TOGGLE,
      }
    })

    it('sets expanded to true if it was false', () => {
      state.expanded = false
      expect(folder(state, action).expanded).toBe(true)
    })

    it('sets expanded to false if it was true', () => {
      state.expanded = true
      expect(folder(state, action).expanded).toBe(false)
    })

    it('keeps existing properties', () => {
      state.foo = 'bar'
      expect(folder(state, action).foo).toBe(state.foo)
    })
  })
})
