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
import documentsReducer from '../../../src/sidebar/reducers/documents'
import * as actions from '../../../src/sidebar/actions/documents'
import {CHANGE_CONTEXT} from '../../../src/sidebar/actions/context'

describe('Documents reducer', () => {
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
    assert(documentsReducer(state, {type: 'unknown.action'}) === state)
  })

  describe('REQUEST_DOCS', () => {
    it('marks documents as loading', () => {
      const action = {type: actions.REQUEST_DOCS, payload: {contextType: 'user'}}
      assert(documentsReducer(state, action).user.isLoading)
    })
  })

  describe('REQUEST_INITIAL_DOCS', () => {
    it('marks documents as loading', () => {
      const action = {type: actions.REQUEST_INITIAL_DOCS, payload: {contextType: 'user'}}
      assert(documentsReducer(state, action).user.isLoading)
    })

    it('marks documents as having more', () => {
      const action = {type: actions.REQUEST_INITIAL_DOCS, payload: {contextType: 'user'}}
      assert(documentsReducer(state, action).user.hasMore)
    })

    it('clears files', () => {
      state.course.files = ['one', 'two']
      const action = {type: actions.REQUEST_INITIAL_DOCS, payload: {contextType: 'course'}}
      assert.equal(documentsReducer(state, action).course.files.length, 0)
    })
  })

  describe('RECEIVE_DOCS', () => {
    it('appends new fils to the existing array', () => {
      const action = {
        type: actions.RECEIVE_DOCS,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course'
        }
      }
      assert.equal(documentsReducer(state, action).course.files.length, 2)
    })

    it("hasMore if there's a bookmark", () => {
      const action = {
        type: actions.RECEIVE_DOCS,
        payload: {
          files: [{id: 1}, {id: 2}],
          bookmark: 'some bookmark',
          contextType: 'course'
        }
      }
      assert(documentsReducer(state, action).course.hasMore)
    })

    it('clears isLoading state', () => {
      state.isLoading = true
      const action = {
        type: actions.RECEIVE_DOCS,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course'
        }
      }
      assert.equal(documentsReducer(state, action).course.isLoading, false)
    })
  })

  describe('CHANGE_CONTEXT', () => {
    it('creates the new documents context if it does not exist', () => {
      const action = {
        type: CHANGE_CONTEXT,
        payload: {contextType: 'foobar', contextId: '111'}
      }
      const newDocs = documentsReducer(state, action)

      assert.deepEqual(newDocs.foobar, {
        files: [],
        bookmark: null,
        hasMore: true,
        isLoading: false
      })
    })
  })
})
