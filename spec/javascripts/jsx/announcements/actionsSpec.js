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

import actions from 'jsx/announcements/actions'
import * as apiClient from 'jsx/announcements/apiClient'

let sandbox = null

const mockApiClient = (method, res) => {
  sandbox = sinon.sandbox.create()
  sandbox.stub(apiClient, method).returns(res)
}

const mockSuccess = (method, data = {}) => mockApiClient(method, Promise.resolve(data))
const mockFail = (method, err = new Error('Request Failed')) => mockApiClient(method, Promise.reject(err))

QUnit.module('Announcements redux actions', {
  teardown () {
    if (sandbox) sandbox.restore()
    sandbox = null
  }
})

test('searchAnnouncements dispatches UPDATE_ANNOUNCEMENTS_SEARCH with search term', () => {
  const state = { announcementsSearch: {} }
  const dispatchSpy = sinon.spy()
  actions.searchAnnouncements({ term: 'test' })(dispatchSpy, () => state)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'UPDATE_ANNOUNCEMENTS_SEARCH', payload: { term: 'test' } }])
})

test('searchAnnouncements calls actions.clearAnnouncementsPage when search term updates', () => {
  const getState = () => ({ announcementsSearch: { term: Math.random().toString() }, announcements: { lastPage: 5 } })
  const dispatchSpy = sinon.spy()
  const clearAnnouncementsSpy = sinon.spy(actions, 'clearAnnouncementsPage')
  actions.searchAnnouncements({ term: 'test' })(dispatchSpy, getState)
  deepEqual(clearAnnouncementsSpy.firstCall.args, [{
    pages: [1, 2, 3, 4, 5],
	}])
  clearAnnouncementsSpy.restore()
})

test('searchAnnouncements calls actions.clearAnnouncements when search term updates', () => {
  const getState = () => ({ announcementsSearch: { term: Math.random().toString() }, announcements: { lastPage: 1 } })
  const dispatchSpy = sinon.spy()
  const getAnnouncementsSpy = sinon.spy(actions, 'getAnnouncements')
  actions.searchAnnouncements({ term: 'test' })(dispatchSpy, getState)
  deepEqual(getAnnouncementsSpy.firstCall.args, [{
    page: 1,
    select: true,
	}])
  getAnnouncementsSpy.restore()
})

test('searchAnnouncements does not call actions.getAnnouncements when search term stays the same', () => {
  const getState = () => ({ announcementsSearch: { term: 'test' } })
  const dispatchSpy = sinon.spy()
  const getAnnouncementsSpy = sinon.spy(actions, 'getAnnouncements')
  actions.searchAnnouncements({ term: 'test' })(dispatchSpy, getState)
  equal(getAnnouncementsSpy.callCount, 0)
  getAnnouncementsSpy.restore()
})

test('searchAnnouncements does not call actions.getAnnouncements when filter stays the same', () => {
  const getState = () => ({ announcementsSearch: { filter: 'all' } })
  const dispatchSpy = sinon.spy()
  const getAnnouncementsSpy = sinon.spy(actions, 'getAnnouncements')
  actions.searchAnnouncements({ term: 'all' })(dispatchSpy, getState)
  equal(getAnnouncementsSpy.callCount, 0)
  getAnnouncementsSpy.restore()
})

test('searchAnnouncements calls actions.getAnnouncements when filter updates', () => {
  const getState = () => ({ announcementsSearch: { filter: Math.random().toString() }, announcements: { lastPage: 1 } })
  const dispatchSpy = sinon.spy()
  const getAnnouncementsSpy = sinon.spy(actions, 'getAnnouncements')
  actions.searchAnnouncements({ filter: 'unread' })(dispatchSpy, getState)
  deepEqual(getAnnouncementsSpy.firstCall.args, [{
    page: 1,
    select: true,
  }])
  getAnnouncementsSpy.restore()
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_START', () => {
  const state = { announcements: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const dispatchSpy = sinon.spy()
  actions.toggleAnnouncementsLock()(dispatchSpy, () => state)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'LOCK_ANNOUNCEMENTS_START' }])
})

test(`toggleSelectedAnnouncementsLock calls apiClient.lockAnnouncements with selected announcements
      and locked: true if any selected announcements are unlocked`, () => {
  const state = {
    selectedAnnouncements: [1, 2, 3],
    announcements: {
      currentPage: 1,
      pages: {
        1: {
          items: [{
            id: 1,
            locked: true,
          },
          {
            id: 2,
            locked: true,
          },
          {
            id: 3,
            locked: false,
          }],
        },
      },
    },
  }
  const dispatchSpy = sinon.spy()
  mockSuccess('lockAnnouncements', { successes: [], failures: [] })
  actions.toggleSelectedAnnouncementsLock()(dispatchSpy, () => state)
  deepEqual(apiClient.lockAnnouncements.firstCall.args, [state, state.selectedAnnouncements, true])
})

test('toggleAnnouncementsLock calls apiClient.lockAnnouncements with passed in announcements and lock status', () => {
  const announcements = ['2', '3']
  const state = {
    announcements: {
      currentPage: 1,
      pages: {
        1: {
          items: [{
            id: 1,
            locked: true,
          },
          {
            id: 2,
            locked: true,
          },
          {
            id: 3,
            locked: false,
          }],
        },
      },
    },
  }
  const dispatchSpy = sinon.spy()
  mockSuccess('lockAnnouncements', { successes: [], failures: [] })
  actions.toggleAnnouncementsLock(announcements, true)(dispatchSpy, () => state)
  deepEqual(apiClient.lockAnnouncements.firstCall.args, [state, announcements, true])
})

test(`toggleSelectedAnnouncementsLock calls apiClient.lockAnnouncements with selected announcements
      and locked: false if all the announcements are locked`, () => {
  const state = {
    selectedAnnouncements: [1, 2, 3],
    announcements: {
      currentPage: 1,
      pages: {
        1: {
          items: [{
            id: 1,
            locked: true,
          },
          {
            id: 2,
            locked: true,
          },
          {
            id: 3,
            locked: false,
          }],
        },
      },
    },
  }
  const dispatchSpy = sinon.spy()
  mockSuccess('lockAnnouncements', { successes: [], failures: [] })
  actions.toggleSelectedAnnouncementsLock()(dispatchSpy, () => state)
  deepEqual(apiClient.lockAnnouncements.firstCall.args, [state, state.selectedAnnouncements, true])
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_FAIL if promise fails', (assert) => {
  const done = assert.async()
  const state = { announcements: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const dispatchSpy = sinon.spy()

  mockFail('lockAnnouncements', { err: 'something bad happened' })
  actions.toggleAnnouncementsLock()(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'LOCK_ANNOUNCEMENTS_FAIL')
    done()
  })
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_SUCCESS if promise succeeeds and successes is at least 1', (assert) => {
  const done = assert.async()
  const state = { announcements: { pages: { 1: { items: [{ id: 1 }] } }, currentPage: 1 }, selectedAnnouncements: [] }
  const dispatchSpy = sinon.spy()

  mockSuccess('lockAnnouncements', { successes: [{ data: 1 }], failures: [] })
  actions.toggleAnnouncementsLock()(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'LOCK_ANNOUNCEMENTS_SUCCESS')
    done()
  })
})

test('toggleAnnouncementsLock dispatches LOCK_ANNOUNCEMENTS_FAIL if promise succeeeds, successes is 0, and failures is > 0', (assert) => {
  const done = assert.async()
  const state = { announcements: { pages: { 1: { items: [{ id: 1 }] } }, currentPage: 1 }, selectedAnnouncements: [] }
  const dispatchSpy = sinon.spy()

  mockSuccess('lockAnnouncements', { successes: [], failures: [{ data: 1, err: 'something bad happened' }] })
  actions.toggleAnnouncementsLock()(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'LOCK_ANNOUNCEMENTS_FAIL')
    done()
  })
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_START', () => {
  const state = {}
  const dispatchSpy = sinon.spy()
  actions.deleteAnnouncements()(dispatchSpy, () => state)
  deepEqual(dispatchSpy.firstCall.args, [{ type: 'DELETE_ANNOUNCEMENTS_START' }])
})

test('deleteAnnouncements calls apiClient.deleteAnnouncements with passed in announcements', () => {
  const announcements = [1, 2, 3]
  const dispatchSpy = sinon.spy()
  mockSuccess('deleteAnnouncements', { successes: [], failures: [] })
  actions.deleteAnnouncements(announcements)(dispatchSpy, () => {})
  deepEqual(apiClient.deleteAnnouncements.firstCall.args[1], announcements)
})

test('deleteSelectedAnnouncements calls apiClient.deleteAnnouncements with state selectedAnnouncements', () => {
  const state = { selectedAnnouncements: [1, 2, 3, 5, 8] }
  const dispatchSpy = sinon.spy()
  mockSuccess('deleteAnnouncements', { successes: [], failures: [] })
  actions.deleteSelectedAnnouncements()(dispatchSpy, () => state)
  deepEqual(apiClient.deleteAnnouncements.firstCall.args[1], state.selectedAnnouncements)
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_FAIL if promise fails', (assert) => {
  const done = assert.async()
  const state = {}
  const dispatchSpy = sinon.spy()

  mockFail('deleteAnnouncements', { err: 'something bad happened' })
  actions.deleteAnnouncements()(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'DELETE_ANNOUNCEMENTS_FAIL')
    done()
  })
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_SUCCESS if promise succeeds and successes is at least 1', (assert) => {
  const done = assert.async()
  const state = {}
  const dispatchSpy = sinon.spy()

  mockSuccess('deleteAnnouncements', { successes: [{ data: 1 }], failures: [] })
  actions.deleteAnnouncements()(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'DELETE_ANNOUNCEMENTS_SUCCESS')
    done()
  })
})

test('deleteAnnouncements dispatches DELETE_ANNOUNCEMENTS_FAIL if promise succeeds and successes is less than 1 but failures is at least 1', (assert) => {
  const done = assert.async()
  const state = {}
  const dispatchSpy = sinon.spy()

  mockSuccess('deleteAnnouncements', { successes: [], failures: [{ data: 1 }] })
  actions.deleteAnnouncements()(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'DELETE_ANNOUNCEMENTS_FAIL')
    done()
  })
})

test('deleteAnnouncements clears page cache from current page to last page if request succeeds', (assert) => {
  const done = assert.async()
  const state = { announcements: { currentPage: 3, lastPage: 7 } }
  const dispatchSpy = sinon.spy()

  mockSuccess('deleteAnnouncements', { successes: [{ data: 1 }], failures: [] })
  actions.deleteAnnouncements()(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(dispatchSpy.thirdCall.args[0], { type: 'CLEAR_ANNOUNCEMENTS_PAGE', payload: { pages: [3, 4, 5, 6, 7] } })
    done()
  })
})

test('deleteAnnouncements re-selects the current page if request succeeds', (assert) => {
  const done = assert.async()
  const state = { announcements: { currentPage: 3, lastPage: 7 } }
  const dispatchSpy = sinon.spy()

  mockSuccess('deleteAnnouncements', { successes: [{ data: 1 }], failures: [] })
  actions.deleteAnnouncements()(dispatchSpy, () => state)

  setTimeout(() => {
    ok(dispatchSpy.lastCall.args[0], { type: 'GET_ANNOUNCEMENTS_PAGE', payload: { page: 3, select: true } })
    done()
  })
})
