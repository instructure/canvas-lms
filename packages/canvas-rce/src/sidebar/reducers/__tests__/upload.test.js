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

import upload from '../upload'
import * as actions from '../../actions/upload'

describe('Upload reducer', () => {
  let state
  let action

  beforeEach(() => {
    state = {
      uploading: false,
      formExpanded: false,
      folders: {},
      rootFolderId: null,
      folderTree: {},
      error: {},
      loadingFolders: false,
      uploadingMediaStatus: false,
    }
  })

  it('does not modify the state if for unknown actions', () => {
    expect(upload(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('START_FILE_UPLOAD', () => {
    beforeEach(() => {
      action = {type: actions.START_FILE_UPLOAD}
    })

    it('sets uploading to true', () => {
      expect(upload(state, action).uploading).toBe(true)
    })
  })

  describe('COMPLETE_FILE_UPLOAD', () => {
    beforeEach(() => {
      action = {
        type: actions.COMPLETE_FILE_UPLOAD,
        results: {
          thumbnail_url: 'http://some.url.example.com',
        },
      }
    })

    it('turns uploading off', () => {
      expect(upload(state, action).uploading).toBe(false)
    })

    it('collapses the form', () => {
      state.formExpanded = true
      expect(upload(state, action).formExpanded).toBe(false)
    })

    it('resets the error state', () => {
      state.error = {type: 'SOME_ERROR'}
      expect(upload(state, action).error).toEqual({})
    })
  })

  describe('FAIL_FILE_UPLOAD', () => {
    beforeEach(() => {
      action = {type: actions.FAIL_FILE_UPLOAD}
    })

    it('disables uploading flag', () => {
      expect(upload(state, action).uploading).toBe(false)
    })

    it('leaves the form state as it is', () => {
      expect(upload(state, action).formExpanded).toBe(state.formExpanded)
    })
  })

  describe('QUOTA_EXCEEDED_UPLOAD', () => {
    beforeEach(() => {
      action = {type: actions.QUOTA_EXCEEDED_UPLOAD}
    })

    it('sets the error state type to QUOTA_EXCEEDED_UPLOAD', () => {
      expect(upload(state, action).error.type).toBe('QUOTA_EXCEEDED_UPLOAD')
    })

    it('sets the uploading state the false', () => {
      expect(upload(state, action).uploading).toBe(false)
    })
  })

  describe('RECEIVE_FOLDER', () => {
    beforeEach(() => {
      action = {
        type: actions.RECEIVE_FOLDER,
        id: 1,
        name: 'course files',
        parentId: null,
      }
    })

    it('adds a new property to folders keyed by id from action', () => {
      expect(upload(state, action).folders[action.id]).toBeTruthy()
    })

    it('sets id from action', () => {
      expect(upload(state, action).folders[action.id].id).toBe(action.id)
    })

    it('sets name from action', () => {
      expect(upload(state, action).folders[action.id].name).toBe(action.name)
    })

    it('keeps existing properties', () => {
      state.folders = {foo: 'bar'}
      expect(upload(state, action).folders.foo).toBe(state.folders.foo)
    })

    it('sets the root folder id', () => {
      expect(upload(state, action).rootFolderId).toBe(1)
    })
  })

  describe('FAIL_FOLDERS_LOAD', () => {
    beforeEach(() => {
      action = {type: actions.FAIL_FOLDERS_LOAD}
    })

    it('empties the folders data', () => {
      expect(Object.keys(upload(state, action).folders).length).toBe(0)
    })

    it('sets loadingFolders to false', () => {
      expect(upload(state, action).loadingFolders).toBe(false)
    })
  })

  describe('TOGGLE_UPLOAD_FORM', () => {
    beforeEach(() => {
      action = {type: actions.TOGGLE_UPLOAD_FORM}
      state.formExpanded = true
    })

    it('reverses current state', () => {
      expect(upload(state, action).formExpanded).toBe(!state.formExpanded)
    })

    it('goes back and forth for each invocation', () => {
      state.formExpanded = false
      expect(upload(state, action).formExpanded).toBe(true)
    })
  })

  describe('PROCESSED_FOLDER_BATCH', () => {
    it('builds a folder tree with sorting', () => {
      action = {
        type: actions.PROCESSED_FOLDER_BATCH,
        folders: {
          1: {id: 1, name: 'course files', parentId: null},
          2: {id: 2, name: 'b', parentId: 1},
          3: {id: 3, name: 'a', parentId: 1},
          4: {id: 4, name: 'c', parentId: 1},
          5: {id: 5, name: 'ac', parentId: 3},
          6: {id: 6, name: 'ab', parentId: 3},
          7: {id: 7, name: 'ba', parentId: 2},
          8: {id: 8, name: 'aa', parentId: 3},
          9: {id: 9, name: 'bc', parentId: 2},
        },
      }
      const desiredTree = {
        1: [3, 2, 4],
        2: [7, 9],
        3: [8, 6, 5],
        4: [],
        5: [],
        6: [],
        7: [],
        8: [],
        9: [],
      }
      expect(upload(state, action).folderTree).toEqual(desiredTree)
    })
  })

  describe('START_LOADING', () => {
    beforeEach(() => {
      action = {type: actions.START_LOADING}
    })

    it('sets loadingFolders to true', () => {
      expect(upload(state, action).loadingFolders).toBe(true)
    })

    it('sets uploadingMediaStatus loading true', () => {
      expect(upload(state, action).uploadingMediaStatus).toEqual({
        loading: true,
        uploaded: false,
        error: false,
      })
    })
  })

  describe('FAIL_MEDIA_UPLOAD', () => {
    beforeEach(() => {
      action = {type: actions.FAIL_MEDIA_UPLOAD}
    })

    it('sets uploadingMediaStatus error to true', () => {
      expect(upload(state, action).uploadingMediaStatus).toEqual({
        loading: false,
        uploaded: false,
        error: true,
      })
    })
  })

  describe('MEDIA_UPLOAD_SUCCESS', () => {
    beforeEach(() => {
      action = {type: actions.MEDIA_UPLOAD_SUCCESS}
    })

    it('sets uploadingMediaStatus uploaded to true', () => {
      expect(upload(state, action).uploadingMediaStatus).toEqual({
        loading: false,
        uploaded: true,
        error: false,
      })
    })
  })

  describe('STOP_LOADING', () => {
    beforeEach(() => {
      action = {type: actions.STOP_LOADING}
    })

    it('sets loadingFolders to false', () => {
      expect(upload(state, action).loadingFolders).toBe(false)
    })
  })
})
