/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import sinon from 'sinon'
import * as actions from '../../../src/sidebar/actions/documents'

const sortBy = {sort: 'alphabetical', order: 'asc'}

describe('Documents actions', () => {
  describe('fetchDocuments', () => {
    it('fetches initial page', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          documents: {
            user: {
              files: [],
              bookmark: null,
              hasMore: true,
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchInitialDocs(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('fetches subsequent page if necessary', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          documents: {
            user: {
              files: [],
              bookmark: null,
              hasMore: true,
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextDocs(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('skips the fetch if currently loading', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          documents: {
            user: {
              files: [{one: '1'}, {two: '2'}, {three: '3'}],
              bookmark: 'someurl',
              hasMore: true,
              isLoading: true
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextDocs(sortBy)(dispatchSpy, getState)
      assert(!dispatchSpy.called)
    })
    it('always fetches initial page', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          documents: {
            user: {
              files: [{one: '1'}, {two: '2'}, {three: '3'}],
              hasMore: false,
              bookmark: null,
              isLoading: true
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchInitialDocs(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('does not fetch if requested but no more to load', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          documents: {
            user: {
              files: [{one: '1'}, {two: '2'}, {three: '3'}],
              hasMore: false,
              bookmark: 'someurl',
              isLoading: false,
              requested: true
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextDocs(sortBy)(dispatchSpy, getState)
      assert(!dispatchSpy.called)
    })
  })
})
