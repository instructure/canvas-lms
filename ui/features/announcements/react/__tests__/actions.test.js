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
import {deleteAnnouncements, lockAnnouncements} from '../apiClient'

jest.mock('../apiClient', () => ({
  ...jest.requireActual('../apiClient'),
  lockAnnouncements: jest.fn(),
  deleteAnnouncements: jest.fn(),
}))

beforeEach(() => {
  lockAnnouncements.mockImplementation(() => Promise.resolve({successes: [], failures: []}))
  deleteAnnouncements.mockImplementation(() => Promise.resolve({successes: [], failures: []}))
})

afterEach(() => {
  jest.restoreAllMocks()
})

test('searchAnnouncements dispatches UPDATE_ANNOUNCEMENTS_SEARCH with search term', () => {
  const state = {announcementsSearch: {}}
  const dispatchSpy = jest.fn()
  actions.searchAnnouncements({term: 'test'})(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenCalledWith({
    type: 'UPDATE_ANNOUNCEMENTS_SEARCH',
    payload: {term: 'test'},
  })
})

test('searchAnnouncements calls actions.clearAnnouncementsPage when search term updates', () => {
  const getState = () => ({
    announcementsSearch: {term: Math.random().toString()},
    announcements: {lastPage: 5},
  })
  const dispatchSpy = jest.fn()
  const clearAnnouncementsSpy = jest.spyOn(actions, 'clearAnnouncementsPage')
  actions.searchAnnouncements({term: 'test'})(dispatchSpy, getState)
  expect(clearAnnouncementsSpy).toHaveBeenCalledWith({
    pages: [1, 2, 3, 4, 5],
  })
})

test('searchAnnouncements calls actions.clearAnnouncements when search term updates', () => {
  const getState = () => ({
    announcementsSearch: {term: Math.random().toString()},
    announcements: {lastPage: 1},
  })
  const dispatchSpy = jest.fn()
  const getAnnouncementsSpy = jest.spyOn(actions, 'getAnnouncements')
  actions.searchAnnouncements({term: 'test'})(dispatchSpy, getState)
  expect(getAnnouncementsSpy).toHaveBeenCalledWith({
    page: 1,
    select: true,
  })
})

test('searchAnnouncements does not call actions.getAnnouncements when search term stays the same', () => {
  const getState = () => ({announcementsSearch: {term: 'test'}})
  const dispatchSpy = jest.fn()
  const getAnnouncementsSpy = jest.spyOn(actions, 'getAnnouncements')
  actions.searchAnnouncements({term: 'test'})(dispatchSpy, getState)
  expect(getAnnouncementsSpy).not.toHaveBeenCalled()
})

test('searchAnnouncements does not call actions.getAnnouncements when filter stays the same', () => {
  const getState = () => ({announcementsSearch: {filter: 'all'}})
  const dispatchSpy = jest.fn()
  const getAnnouncementsSpy = jest.spyOn(actions, 'getAnnouncements')
  actions.searchAnnouncements({term: 'all'})(dispatchSpy, getState)
  expect(getAnnouncementsSpy).not.toHaveBeenCalled()
})

test('searchAnnouncements calls actions.getAnnouncements when filter updates', () => {
  const getState = () => ({
    announcementsSearch: {filter: Math.random().toString()},
    announcements: {lastPage: 1},
  })
  const dispatchSpy = jest.fn()
  const getAnnouncementsSpy = jest.spyOn(actions, 'getAnnouncements')
  actions.searchAnnouncements({filter: 'unread'})(dispatchSpy, getState)
  expect(getAnnouncementsSpy).toHaveBeenCalledWith({
    page: 1,
    select: true,
  })
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_START', () => {
  const state = {announcements: {pages: {1: {items: []}}, currentPage: 1}}
  const dispatchSpy = jest.fn()
  actions.toggleAnnouncementsLock()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenCalledWith({type: 'LOCK_ANNOUNCEMENTS_START'})
})

test(`toggleSelectedAnnouncementsLock calls apiClient.lockAnnouncements with selected announcements
      and locked: true if any selected announcements are unlocked`, async () => {
  const state = {
    selectedAnnouncements: [1, 2, 3],
    announcements: {
      currentPage: 1,
      pages: {
        1: {
          items: [
            {id: 1, locked: true},
            {id: 2, locked: true},
            {id: 3, locked: false},
          ],
        },
      },
    },
  }
  const dispatchSpy = jest.fn()

  await actions.toggleSelectedAnnouncementsLock()(dispatchSpy, () => state)
  expect(lockAnnouncements).toHaveBeenCalledWith(
    {
      announcements: {
        currentPage: 1,
        pages: {
          1: {
            items: [
              {id: 1, locked: true},
              {id: 2, locked: true},
              {id: 3, locked: false},
            ],
          },
        },
      },
      selectedAnnouncements: [1, 2, 3],
    },
    [1, 2, 3],
    true
  )
})

test('toggleAnnouncementsLock calls apiClient.lockAnnouncements with passed in announcements and lock status', async () => {
  const announcements = ['2', '3']
  const state = {
    announcements: {
      currentPage: 1,
      pages: {
        1: {
          items: [
            {id: 1, locked: true},
            {id: 2, locked: true},
            {id: 3, locked: false},
          ],
        },
      },
    },
  }
  const dispatchSpy = jest.fn()
  await actions.toggleAnnouncementsLock(announcements, true)(dispatchSpy, () => state)
  expect(lockAnnouncements).toHaveBeenCalledWith(
    {
      announcements: {
        currentPage: 1,
        pages: {
          1: {
            items: [
              {id: 1, locked: true},
              {id: 2, locked: true},
              {id: 3, locked: false},
            ],
          },
        },
      },
    },
    ['2', '3'],
    true
  )
})

test(`toggleSelectedAnnouncementsLock calls apiClient.lockAnnouncements with selected announcements
      and locked: false if all the announcements are locked`, async () => {
  const state = {
    selectedAnnouncements: [1, 2, 3],
    announcements: {
      currentPage: 1,
      pages: {
        1: {
          items: [
            {id: 1, locked: true},
            {id: 2, locked: true},
            {id: 3, locked: false},
          ],
        },
      },
    },
  }
  const dispatchSpy = jest.fn()
  await actions.toggleSelectedAnnouncementsLock()(dispatchSpy, () => state)
  expect(lockAnnouncements).toHaveBeenCalledWith(
    {
      announcements: {
        currentPage: 1,
        pages: {
          1: {
            items: [
              {id: 1, locked: true},
              {id: 2, locked: true},
              {id: 3, locked: false},
            ],
          },
        },
      },
      selectedAnnouncements: [1, 2, 3],
    },
    [1, 2, 3],
    true
  )
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_FAIL if promise fails', async () => {
  const state = {announcements: {pages: {1: {items: []}}, currentPage: 1}}
  const dispatchSpy = jest.fn()

  lockAnnouncements.mockResolvedValue({successes: [], failures: [{err: 'something bad happened'}]})
  await actions.toggleAnnouncementsLock()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(2, {
    payload: {
      err: [{err: 'something bad happened'}],
      message: 'An error occurred while updating announcements locked state.',
    },
    type: 'LOCK_ANNOUNCEMENTS_FAIL',
  })
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_SUCCESS if promise succeeds and successes is at least 1', async () => {
  const state = {announcements: {pages: {1: {items: [{id: 1}]}}, selectedAnnouncements: []}}
  const dispatchSpy = jest.fn()
  lockAnnouncements.mockResolvedValue({successes: [{data: 1}], failures: []})
  await actions.toggleAnnouncementsLock()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(2, {
    payload: {
      locked: true,
      res: {failures: [], successes: [{data: 1}]},
    },
    type: 'LOCK_ANNOUNCEMENTS_SUCCESS',
  })
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_FAIL if promise succeeds and successes is 0, and failures is > 0', async () => {
  const state = {announcements: {pages: {1: {items: [{id: 1}]}}, selectedAnnouncements: []}}
  const dispatchSpy = jest.fn()
  lockAnnouncements.mockResolvedValue({
    successes: [],
    failures: [{data: 1, err: 'something bad happened'}],
  })
  await actions.toggleAnnouncementsLock()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(2, {
    payload: {
      err: [{data: 1, err: 'something bad happened'}],
      message: 'An error occurred while updating announcements locked state.',
    },
    type: 'LOCK_ANNOUNCEMENTS_FAIL',
  })
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_START', () => {
  const state = {}
  const dispatchSpy = jest.fn()
  actions.deleteAnnouncements()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenCalledWith({type: 'DELETE_ANNOUNCEMENTS_START'})
})

test('deleteAnnouncements calls apiClient.deleteAnnouncements with passed in announcements', async () => {
  const announcements = [1, 2, 3]
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({successes: [], failures: []})
  await actions.deleteAnnouncements(announcements)(dispatchSpy, () => {})
  expect(deleteAnnouncements).toHaveBeenCalledWith(undefined, announcements)
})

test('deleteSelectedAnnouncements calls apiClient.deleteAnnouncements with state selectedAnnouncements', async () => {
  const state = {selectedAnnouncements: [1, 2, 3, 5, 8]}
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({successes: [], failures: []})
  await actions.deleteSelectedAnnouncements()(dispatchSpy, () => state)
  expect(deleteAnnouncements).toHaveBeenCalledWith(
    {
      selectedAnnouncements: state.selectedAnnouncements,
    },
    state.selectedAnnouncements
  )
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_FAIL if promise fails', async () => {
  const state = {}
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({
    successes: [],
    failures: [{err: 'something bad happened'}],
  })
  await actions.deleteAnnouncements()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(2, {
    payload: {
      err: [{err: 'something bad happened'}],
      message: 'An error occurred while deleting announcements.',
    },
    type: 'DELETE_ANNOUNCEMENTS_FAIL',
  })
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_SUCCESS if promise succeeds and successes is at least 1', async () => {
  const state = {}
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({successes: [{data: 1}], failures: []})
  await actions.deleteAnnouncements()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(2, {
    payload: {
      failures: [],
      successes: [{data: 1}],
    },
    type: 'DELETE_ANNOUNCEMENTS_SUCCESS',
  })
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_FAIL if promise succeeds and successes is less than 1 but failures is at least 1', async () => {
  const state = {}
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({successes: [], failures: [{data: 1}]})
  await actions.deleteAnnouncements()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(2, {
    payload: {
      err: [{data: 1}],
      message: 'An error occurred while deleting announcements.',
    },
    type: 'DELETE_ANNOUNCEMENTS_FAIL',
  })
})

test('deleteAnnouncements clears page cache from current page to last page if request succeeds', async () => {
  const state = {announcements: {currentPage: 3, lastPage: 7}}
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({successes: [{data: 1}], failures: []})
  await actions.deleteAnnouncements()(dispatchSpy, () => state)
  expect(dispatchSpy).toHaveBeenNthCalledWith(3, {
    type: 'CLEAR_ANNOUNCEMENTS_PAGE',
    payload: {pages: [3, 4, 5, 6, 7]},
  })
})

test('deleteAnnouncements re-selects the current page if request succeeds', async () => {
  const state = {announcements: {currentPage: 3, lastPage: 7}}
  const dispatchSpy = jest.fn()
  deleteAnnouncements.mockResolvedValue({successes: [{data: 1}], failures: []})
  await actions.deleteAnnouncements()(dispatchSpy, () => state)

  // unfortunately, since moving to jest, the deepest we can expect is that
  // we passed in an anonymous function.
  expect(dispatchSpy).toHaveBeenNthCalledWith(5, expect.any(Function))
})
