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

import assert from 'assert'
import images from '../../../src/sidebar/reducers/images'
import * as actions from '../../../src/sidebar/actions/images'

describe('Images reducer', () => {
  let state

  beforeEach(() => {
    state = {
      course: {
        files: [],
        bookmark: null,
        hasMore: false,
        isLoading: false
      },
      contextType: 'course'
    }
  })

  it('does not modify the state if for unknown actions', () => {
    assert(images(state, {type: 'unknown.action'}) === state)
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
            thumbnail_url: 'other_url'
          },
          contextType: 'course'
        }
      }
    })

    it('adds a new object to images array', () => {
      assert(images(state, action).course.files[0])
    })

    it('sets id from action', () => {
      assert(images(state, action).course.files[0].id === action.payload.newImage.id)
    })

    it('sets filename from action', () => {
      assert(images(state, action).course.files[0].filename === action.payload.newImage.filename)
    })

    it('sets display_name from action display_name', () => {
      assert(images(state, action).course.files[0].type === action.payload.newImage.fileType)
    })

    it('sets preview_url from action preview_url', () => {
      assert(
        images(state, action).course.files[0].preview_url === action.payload.newImage.preview_url
      )
    })

    it('sets thumbnail_url from action thumbnail_url', () => {
      assert(
        images(state, action).course.files[0].thumbnail_url ===
          action.payload.newImage.thumbnail_url
      )
    })

    it('sets href from action preview_url', () => {
      assert(images(state, action).course.files[0].href === action.payload.newImage.preview_url)
    })
  })

  describe('RECEIVE_IMAGES', () => {
    it('appends new records to the existing array', () => {
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course'
        }
      }
      assert.equal(images(state, action).course.files.length, 2)
    })

    it("hasMore if there's a bookmark", () => {
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          bookmark: 'some bookmark',
          contextType: 'course'
        }
      }
      assert(images(state, action).course.hasMore)
    })

    it('clears isLoading state', () => {
      state.isLoading = true
      const action = {
        type: actions.RECEIVE_IMAGES,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course'
        }
      }
      assert.equal(images(state, action).course.isLoading, false)
    })
  })

  describe('REQUEST_IMAGES', () => {
    it('marks images as loading', () => {
      const action = {type: actions.REQUEST_IMAGES, payload: {contextType: 'user'}}
      assert(images(state, action).user.isLoading)
    })
  })

  describe('REQUEST_INITIAL_IMAGES', () => {
    it('marks images as loading', () => {
      const action = {type: actions.REQUEST_INITIAL_IMAGES, payload: {contextType: 'user'}}
      assert(images(state, action).user.isLoading)
    })

    it('marks iamgess as having more', () => {
      const action = {type: actions.REQUEST_INITIAL_IMAGES, payload: {contextType: 'user'}}
      assert(images(state, action).user.hasMore)
    })

    it('clears files', () => {
      state.course.files = ['one', 'two']
      const action = {type: actions.REQUEST_INITIAL_IMAGES, payload: {contextType: 'course'}}
      assert.equal(images(state, action).course.files.length, 0)
    })
  })
})
