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
import reducer from 'jsx/announcements/reducer'

QUnit.module('Announcements reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('UPDATE_ANNOUNCEMENTS_SEARCH should not update term when term is not defined', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({}), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, 'test')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to empty string when term is shorter than 3 chars', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ term: 'te' }), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, '')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to empty string when term is empty string', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ term: '' }), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, '')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to term in payload when term is at least 3 chars', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ term: 'foo' }), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, 'foo')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should not update filter when filter is not defined', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({}), {
    announcementsSearch: { filter : 'all' },
  })
  deepEqual(newState.announcementsSearch.filter, 'all')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update filter to filter in payload', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ filter: 'unread' }), {
    announcementsSearch: { filter: 'all' },
  })
  deepEqual(newState.announcementsSearch.filter, 'unread')
})

test('LOCK_ANNOUNCEMENTS_START should set isLockingAnnouncements to true', () => {
  const newState = reduce(actions.lockAnnouncementsStart(), {
    isLockingAnnouncements: false,
  })
  ok(newState.isLockingAnnouncements)
})

test('LOCK_ANNOUNCEMENTS_SUCCESS should set isLockingAnnouncements to false', () => {
  const newState = reduce(actions.lockAnnouncementsSuccess(), {
    isLockingAnnouncements: true,
  })
  notOk(newState.isLockingAnnouncements)
})

test('LOCK_ANNOUNCEMENTS_SUCCESS should updated the locked status of successful operations on the current page', () => {
  const newState = reduce(actions.lockAnnouncementsSuccess({
    locked: true,
    res: {
      successes: [
        {data: 2},
        {data: 3},
      ],
    },
  }), {
    announcements: {
      currentPage: 1,
      lastPage: 1,
      pages: {
        1: {
          items: [
            {
              id: 1,
              locked: false,
            },
            {
              id: 2,
              locked: false,
            },
            {
              id: 3,
              locked: true,
            }
          ],
        },
      },
    },
  })
  deepEqual(newState.announcements.pages, {
    1: {
      items: [
        {
          id: 1,
          locked: false,
        },
        {
          id: 2,
          locked: true,
        },
        {
          id: 3,
          locked: true,
        }
      ],
    },
  })
})

test('LOCK_ANNOUNCEMENTS_FAIL should set isLockingAnnouncements to false', () => {
  const newState = reduce(actions.lockAnnouncementsFail(), {
    isLockingAnnouncements: true,
  })
  notOk(newState.isLockingAnnouncements)
})

test('DELETE_ANNOUNCEMENTS_START should set isDeletingAnnouncements to true', () => {
  const newState = reduce(actions.deleteAnnouncementsStart(), {
    isDeletingAnnouncements: false,
  })
  ok(newState.isDeletingAnnouncements)
})

test('DELETE_ANNOUNCEMENTS_SUCCESS should set isDeletingAnnouncements to false', () => {
  const newState = reduce(actions.deleteAnnouncementsSuccess(), {
    isDeletingAnnouncements: true,
  })
  notOk(newState.isDeletingAnnouncements)
})

test('DELETE_ANNOUNCEMENTS_FAIL should set isDeletingAnnouncements to false', () => {
  const newState = reduce(actions.deleteAnnouncementsFail(), {
    isDeletingAnnouncements: true,
  })
  notOk(newState.isDeletingAnnouncements)
})

test('SET_ANNOUNCEMENT_SELECTION with selected: true should add an announcement to selectedAnnouncements', () => {
  const newState = reduce(actions.setAnnouncementSelection({ selected: true, id: 2 }), {
    selectedAnnouncements: [3],
  })
  deepEqual(newState.selectedAnnouncements, [3, 2])
})

test('SET_ANNOUNCEMENT_SELECTION with selected: true should add an announcement to selectedAnnouncements ignoring duplicates', () => {
  const newState = reduce(actions.setAnnouncementSelection({ selected: true, id: 3 }), {
    selectedAnnouncements: [3],
  })
  deepEqual(newState.selectedAnnouncements, [3])
})

test('SET_ANNOUNCEMENT_SELECTION with selected: false should remove an announcement from selectedAnnouncements', () => {
  const newState = reduce(actions.setAnnouncementSelection({ selected: false, id: 2 }), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [3])
})

test('SET_ANNOUNCEMENT_SELECTION with selected: false should should do nothing if id not in selectedAnnouncements', () => {
  const newState = reduce(actions.setAnnouncementSelection({ selected: false, id: 5 }), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [2, 3])
})

test('CLEAR_ANNOUNCEMENT_SELECTIONS should reset selectedAnnouncements', () => {
  const newState = reduce(actions.clearAnnouncementSelections(), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [])
})

test('DELETE_ANNOUNCEMENTS_SUCCESS should reset selectedAnnouncements', () => {
  const newState = reduce(actions.deleteAnnouncementsSuccess(), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [])
})
