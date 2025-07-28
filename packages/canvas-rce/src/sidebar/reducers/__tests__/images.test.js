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

import {CHANGE_SEARCH_STRING} from '../../actions/filter'
import images from '../images'
import * as actions from '../../actions/images'

describe('Images reducer', () => {
  let state

  beforeEach(() => {
    state = {
      course: {
        files: [],
        bookmark: null,
        hasMore: false,
        isLoading: false,
      },
      contextType: 'course',
      searchString: '',
    }
  })

  it('does not modify the state if for unknown actions', () => {
    expect(images(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('ADD_IMAGE', () => {
    let action

    beforeEach(() => {
      action = {
        type: actions.ADD_IMAGE,
        payload: {
          newImage: {
            id: 1,
            filename: 'Foo',
            display_name: 'Bar',
            preview_url: 'some_url',
            thumbnail_url: 'other_url',
          },
          contextType: 'course',
        },
      }
    })

    it('adds a new object to images array', () => {
      expect(images(state, action).course.files[0]).toBeTruthy()
    })

    it('sets id from action', () => {
      expect(images(state, action).course.files[0].id).toBe(action.payload.newImage.id)
    })

    it('sets filename from action', () => {
      expect(images(state, action).course.files[0].filename).toBe(action.payload.newImage.filename)
    })

    it('sets display_name from action display_name', () => {
      expect(images(state, action).course.files[0].type).toBe(action.payload.newImage.fileType)
    })

    it('sets preview_url from action preview_url', () => {
      expect(images(state, action).course.files[0].preview_url).toBe(
        action.payload.newImage.preview_url,
      )
    })

    it('sets thumbnail_url from action thumbnail_url', () => {
      expect(images(state, action).course.files[0].thumbnail_url).toBe(
        action.payload.newImage.thumbnail_url,
      )
    })

    it('sets href from action preview_url', () => {
      expect(images(state, action).course.files[0].href).toBe(action.payload.newImage.preview_url)
    })
  })

  describe('RECEIVE_IMAGES', () => {
    it('appends new records to the existing array when the payload searchString matches state', () => {
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course',
          searchString: 'panda',
        },
      }

      state.searchString = 'panda'
      expect(images(state, action).course.files).toHaveLength(2)
    })

    it('does not append new records to the existing array when the payload searchString does not match state', () => {
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course',
          searchString: 'panda',
        },
      }

      state.searchString = 'cat'
      expect(images(state, action).course.files).toHaveLength(0)
    })

    it("hasMore if there's a bookmark", () => {
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          bookmark: 'some bookmark',
          contextType: 'course',
          searchString: '',
        },
      }
      expect(images(state, action).course.hasMore).toBe(true)
    })

    it('clears isLoading state', () => {
      state.isLoading = true
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course',
        },
      }
      expect(images(state, action).course.isLoading).toBe(false)
    })
  })

  describe('REQUEST_IMAGES', () => {
    it('marks images as loading', () => {
      const action = {type: actions.REQUEST_IMAGES, payload: {contextType: 'user'}}
      expect(images(state, action).user.isLoading).toBe(true)
    })
  })

  describe('REQUEST_INITIAL_IMAGES', () => {
    it('marks images as loading', () => {
      const action = {type: actions.REQUEST_INITIAL_IMAGES, payload: {contextType: 'user'}}
      expect(images(state, action).user.isLoading).toBe(true)
    })

    it('marks images as having more', () => {
      const action = {type: actions.REQUEST_INITIAL_IMAGES, payload: {contextType: 'user'}}
      expect(images(state, action).user.hasMore).toBe(true)
    })

    it('clears files', () => {
      state.course.files = ['one', 'two']
      const action = {type: actions.REQUEST_INITIAL_IMAGES, payload: {contextType: 'course'}}
      expect(images(state, action).course.files).toHaveLength(0)
    })
  })

  describe('CHANGE_SEARCH_STRING', () => {
    it('sets the searchString to the payload', () => {
      const action = {type: CHANGE_SEARCH_STRING, payload: 'panda'}
      expect(images(state, action).searchString).toBe('panda')
    })
  })
})
