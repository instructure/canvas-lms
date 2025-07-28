/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import actions from '../actions'
import * as apiClient from '../apiClient'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'

jest.mock('../apiClient')

describe('Discussions redux actions', () => {
  const getState = () => ({
    discussions: {
      pages: {1: {items: []}},
      currentPage: 1,
    },
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('updateDiscussion', () => {
    it('dispatches UPDATE_DISCUSSION_SUCCESS when successful', async () => {
      const mockResponse = {data: {locked: false, pinned: true}}
      apiClient.updateDiscussion.mockResolvedValue(mockResponse)

      const discussion = {pinned: false, locked: false}
      const updateFields = {pinned: true}
      const dispatch = jest.fn()

      await actions.updateDiscussion(discussion, updateFields, {})(dispatch, getState)

      expect(dispatch).toHaveBeenCalledWith({
        type: 'UPDATE_DISCUSSION_SUCCESS',
        payload: {
          discussion: {
            locked: false,
            pinned: true,
          },
        },
      })
    })

    it('calls apiClient.updateDiscussion with correct parameters', async () => {
      apiClient.updateDiscussion.mockResolvedValue({})

      const discussion = {pinned: true, locked: true}
      const updateFields = {pinned: false}
      const dispatch = jest.fn()

      await actions.updateDiscussion(discussion, updateFields, {})(dispatch, getState)

      expect(apiClient.updateDiscussion).toHaveBeenCalledWith(
        expect.anything(),
        discussion,
        updateFields,
      )
    })

    it('dispatches UPDATE_DISCUSSION_FAIL when request fails', async () => {
      const error = new Error('something bad happened')
      apiClient.updateDiscussion.mockRejectedValue(error)

      const discussion = {pinned: true, locked: false}
      const updateFields = {locked: true}
      const dispatch = jest.fn()

      try {
        await actions.updateDiscussion(discussion, updateFields, {})(dispatch, getState)
      } catch (_e) {
        expect(dispatch).toHaveBeenCalledWith({
          type: 'UPDATE_DISCUSSION_START',
        })
        expect(dispatch).toHaveBeenCalledWith({
          type: 'UPDATE_DISCUSSION_FAIL',
          payload: {
            err: error,
            message: 'Updating discussion failed',
          },
        })
      }
    })

    it('shows success message when successful and message is provided', async () => {
      apiClient.updateDiscussion.mockResolvedValue({})
      const screenReaderSpy = jest.spyOn($, 'screenReaderFlashMessage')

      const discussion = {pinned: true, locked: false}
      const updateFields = {locked: true}
      const flashMessages = {successMessage: 'success message'}
      const dispatch = jest.fn()

      await actions.updateDiscussion(discussion, updateFields, flashMessages)(dispatch, getState)

      expect(screenReaderSpy).toHaveBeenCalledWith('success message')
    })

    it('does not show success message when successful but no message provided', async () => {
      apiClient.updateDiscussion.mockResolvedValue({})
      const screenReaderSpy = jest.spyOn($, 'screenReaderFlashMessage')

      const discussion = {pinned: true, locked: false}
      const updateFields = {locked: true}
      const dispatch = jest.fn()

      await actions.updateDiscussion(discussion, updateFields, {})(dispatch, getState)

      expect(screenReaderSpy).not.toHaveBeenCalled()
    })

    it('shows failure message when unsuccessful with custom message', async () => {
      const error = new Error('badness occurred')
      apiClient.updateDiscussion.mockRejectedValue(error)
      const screenReaderSpy = jest.spyOn($, 'screenReaderFlashMessage')

      const discussion = {pinned: true, locked: false}
      const updateFields = {locked: true}
      const flashMessages = {failMessage: 'fail message'}
      const dispatch = jest.fn()

      try {
        await actions.updateDiscussion(discussion, updateFields, flashMessages)(dispatch, getState)
      } catch (_e) {
        expect(screenReaderSpy).toHaveBeenCalledWith('fail message')
      }
    })
  })

  describe('handleDrop', () => {
    it('throws exception if updating a non-existent field', () => {
      const state = {
        allDiscussions: {
          1: {id: 1, pinned: false},
          2: {id: 2, pinned: true},
        },
        pinnedDiscussionIds: [2],
        unpinnedDiscussionIds: [1],
        closedForCommentsDiscussions: [],
      }
      const discussion = {pinned: true, locked: false}
      const updateFields = {foobar: true}
      const dispatch = jest.fn()

      expect(() => {
        actions.handleDrop(discussion, updateFields, {})(dispatch, () => state)
      }).toThrow('field foobar does not exist in the discussion')
    })

    it('dispatches DRAG_AND_DROP_START', async () => {
      apiClient.updateDiscussion.mockResolvedValue({})
      apiClient.reorderPinnedDiscussions.mockResolvedValue({})

      const state = {
        allDiscussions: {
          1: {id: 1, pinned: false},
          2: {id: 2, pinned: true},
        },
        pinnedDiscussionIds: [2],
        unpinnedDiscussionIds: [1],
        closedForCommentsDiscussions: [],
      }
      const dispatch = jest.fn()
      const discussion = {id: 1, pinned: false}
      const updateFields = {pinned: true}
      const order = [1, 2]

      await actions.handleDrop(discussion, updateFields, order)(dispatch, () => state)

      expect(dispatch).toHaveBeenCalledWith({
        type: 'DRAG_AND_DROP_START',
        payload: {
          discussion: {
            id: 1,
            pinned: true,
          },
          order,
        },
      })
    })

    it('does not call reorderPinnedDiscussions if ordering not present', async () => {
      apiClient.updateDiscussion.mockResolvedValue({})

      const state = {
        allDiscussions: {
          1: {id: 1, pinned: false},
          2: {id: 2, pinned: true},
        },
        pinnedDiscussionIds: [2],
        unpinnedDiscussionIds: [1],
        closedForCommentsDiscussions: [],
      }
      const dispatch = jest.fn()

      await actions.handleDrop({id: 1, pinned: false}, {pinned: true})(dispatch, () => state)

      expect(apiClient.reorderPinnedDiscussions).not.toHaveBeenCalled()
    })
  })
})
