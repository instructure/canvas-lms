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
import documentsReducer from '../documents'
import * as actions from '../../actions/documents'
import {CHANGE_CONTEXT} from '../../actions/filter'

describe('Documents reducer', () => {
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
    }
  })

  it('does not modify the state if for unknown actions', () => {
    expect(documentsReducer(state, {type: 'unknown.action'})).toBe(state)
  })

  describe('REQUEST_DOCS', () => {
    it('marks documents as loading', () => {
      const action = {type: actions.REQUEST_DOCS, payload: {contextType: 'user'}}
      expect(documentsReducer(state, action).user.isLoading).toBe(true)
    })
  })

  describe('REQUEST_INITIAL_DOCS', () => {
    it('marks documents as loading', () => {
      const action = {type: actions.REQUEST_INITIAL_DOCS, payload: {contextType: 'user'}}
      expect(documentsReducer(state, action).user.isLoading).toBe(true)
    })

    it('marks documents as having more', () => {
      const action = {type: actions.REQUEST_INITIAL_DOCS, payload: {contextType: 'user'}}
      expect(documentsReducer(state, action).user.hasMore).toBe(true)
    })

    it('clears files', () => {
      state.course.files = ['one', 'two']
      const action = {type: actions.REQUEST_INITIAL_DOCS, payload: {contextType: 'course'}}
      expect(documentsReducer(state, action).course.files).toHaveLength(0)
    })
  })

  describe('RECEIVE_DOCS', () => {
    it('appends new fils to the existing array', () => {
      const action = {
        type: actions.RECEIVE_DOCS,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course',
        },
      }
      expect(documentsReducer(state, action).course.files).toHaveLength(2)
    })

    it("hasMore if there's a bookmark", () => {
      const action = {
        type: actions.RECEIVE_DOCS,
        payload: {
          files: [{id: 1}, {id: 2}],
          bookmark: 'some bookmark',
          contextType: 'course',
        },
      }
      expect(documentsReducer(state, action).course.hasMore).toBe(true)
    })

    it('clears isLoading state', () => {
      state.isLoading = true
      const action = {
        type: actions.RECEIVE_DOCS,
        payload: {
          files: [{id: 1}, {id: 2}],
          contextType: 'course',
        },
      }
      expect(documentsReducer(state, action).course.isLoading).toBe(false)
    })
  })

  describe('CHANGE_CONTEXT', () => {
    it('creates the new documents context if it does not exist', () => {
      const action = {
        type: CHANGE_CONTEXT,
        payload: {contextType: 'foobar', contextId: '111'},
      }
      const newDocs = documentsReducer(state, action)

      expect(newDocs.foobar).toEqual({
        files: [],
        bookmark: null,
        hasMore: true,
        isLoading: false,
      })
    })
  })
})
