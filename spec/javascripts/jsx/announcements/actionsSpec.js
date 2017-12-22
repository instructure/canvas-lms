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

QUnit.module('Announcements redux actions')

test('searchAnnouncements dispatches UPDATE_ANNOUNCEMENTS_SEARCH with search term', () => {
  const state = { announcementsSearch: {} }
  const dispatchSpy = sinon.spy()
  actions.searchAnnouncements({ term: 'test' })(dispatchSpy, () => state)
  deepEqual(dispatchSpy.firstCall.args[0], { type: 'UPDATE_ANNOUNCEMENTS_SEARCH', payload: { term: 'test' } })
})

test('searchAnnouncements calls actions.getAnnouncements when search term updates', () => {
  const getState = () => ({ announcementsSearch: { term: Math.random().toString() } })
  const dispatchSpy = sinon.spy()
  const getAnnouncementsSpy = sinon.spy(actions, 'getAnnouncements')
  actions.searchAnnouncements({ term: 'test' })(dispatchSpy, getState)
  deepEqual(getAnnouncementsSpy.firstCall.args[0], {
    forceGet: true,
    page: 1,
    select: true,
	})
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
