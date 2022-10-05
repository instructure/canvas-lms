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

import actions from 'ui/features/announcements/react/actions'
import reducer from 'ui/features/announcements/react/reducer'

QUnit.module('Announcements reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('UPDATE_ANNOUNCEMENTS_SEARCH should not update term when term is not defined', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({}), {
    announcementsSearch: {term: 'test'},
  })
  deepEqual(newState.announcementsSearch.term, 'test')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to empty string when term is shorter than 3 chars', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({term: 'te'}), {
    announcementsSearch: {term: 'test'},
  })
  deepEqual(newState.announcementsSearch.term, '')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to empty string when term is empty string', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({term: ''}), {
    announcementsSearch: {term: 'test'},
  })
  deepEqual(newState.announcementsSearch.term, '')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to term in payload when term is at least 3 chars', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({term: 'foo'}), {
    announcementsSearch: {term: 'test'},
  })
  deepEqual(newState.announcementsSearch.term, 'foo')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should not update filter when filter is not defined', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({}), {
    announcementsSearch: {filter: 'all'},
  })
  deepEqual(newState.announcementsSearch.filter, 'all')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update filter to filter in payload', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({filter: 'unread'}), {
    announcementsSearch: {filter: 'all'},
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
  const newState = reduce(
    actions.lockAnnouncementsSuccess({
      locked: true,
      res: {
        successes: [{data: 2}, {data: 3}],
      },
    }),
    {
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
              },
            ],
          },
        },
      },
    }
  )
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
        },
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
  const newState = reduce(actions.setAnnouncementSelection({selected: true, id: 2}), {
    selectedAnnouncements: [3],
  })
  deepEqual(newState.selectedAnnouncements, [3, 2])
})

test('SET_ANNOUNCEMENT_SELECTION with selected: true should add an announcement to selectedAnnouncements ignoring duplicates', () => {
  const newState = reduce(actions.setAnnouncementSelection({selected: true, id: 3}), {
    selectedAnnouncements: [3],
  })
  deepEqual(newState.selectedAnnouncements, [3])
})

test('SET_ANNOUNCEMENT_SELECTION with selected: false should remove an announcement from selectedAnnouncements', () => {
  const newState = reduce(actions.setAnnouncementSelection({selected: false, id: 2}), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [3])
})

test('SET_ANNOUNCEMENT_SELECTION with selected: false should should do nothing if id not in selectedAnnouncements', () => {
  const newState = reduce(actions.setAnnouncementSelection({selected: false, id: 5}), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [2, 3])
})

test('ANNOUNCEMENT_SELECTION_CHANGE_START with selected: false should should do nothing if id not in selectedAnnouncements', () => {
  const newState = reduce(actions.announcementSelectionChangeStart({selected: false, id: 5}), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [2, 3])
})

test('SET_ANNOUNCEMENTS_IS_LOCKING should properly set when changed to true', () => {
  const newState = reduce(actions.setAnnouncementsIsLocking(true), {
    isToggleLocking: false,
  })
  deepEqual(newState.isToggleLocking, true)
})

test('DELETE_ANNOUNCEMENTS_SUCCESS should reset selectedAnnouncements', () => {
  const newState = reduce(actions.deleteAnnouncementsSuccess(), {
    selectedAnnouncements: [2, 3],
  })
  deepEqual(newState.selectedAnnouncements, [])
})

test('ADD_EXTERNAL_FEED_START should set saving to true', () => {
  const newState = reduce(actions.addExternalFeedStart(), {
    addExternalFeed: {isSaving: false},
  })
  equal(newState.externalRssFeed.isSaving, true)
})

test('ADD_EXTERNAL_FEED_FAIL should set saving to false', () => {
  const newState = reduce(actions.addExternalFeedFail(), {
    addExternalFeed: {isSaving: true},
  })
  equal(newState.externalRssFeed.isSaving, false)
})

test('ADD_EXTERNAL_FEED_SUCCESS should set saving to false', () => {
  const newState = reduce(actions.addExternalFeedSuccess(), {
    addExternalFeed: {isSaving: true},
  })
  equal(newState.externalRssFeed.isSaving, false)
})

test('LOADING_EXTERNAL_FEED_START should set hasLoadedFeed to false', () => {
  const newState = reduce(actions.loadingExternalFeedStart(), {
    externalRssFeed: {hasLoadedFeed: true},
  })
  equal(newState.externalRssFeed.hasLoadedFeed, false)
})

test('LOADING_EXTERNAL_FEED_FAIL should set hasLoadedFeed to true', () => {
  const newState = reduce(actions.loadingExternalFeedFail(), {
    externalRssFeed: {hasLoadedFeed: false},
  })
  equal(newState.externalRssFeed.hasLoadedFeed, true)
})

test('LOADING_EXTERNAL_FEED_SUCCESS should set hasLoadedFeed to true', () => {
  const newState = reduce(actions.loadingExternalFeedSuccess(), {
    externalRssFeed: {hasLoadedFeed: false},
  })
  equal(newState.externalRssFeed.hasLoadedFeed, true)
})

test('DELETE_EXTERNAL_FEED_START should set isDeleting to true', () => {
  const newState = reduce(actions.deleteExternalFeedStart(), {
    externalRssFeed: {isDeleting: false},
  })
  equal(newState.externalRssFeed.isDeleting, true)
})

test('DELETE_EXTERNAL_FEED_FAIL should set isDeleting to false', () => {
  const newState = reduce(actions.deleteExternalFeedFail(), {
    externalRssFeed: {isDeleting: true},
  })
  equal(newState.externalRssFeed.isDeleting, false)
})

test('DELETE_EXTERNAL_FEED_SUCCESS should set isDeleting to false', () => {
  const newState = reduce(actions.deleteExternalFeedSuccess(), {
    externalRssFeed: {isDeleting: true},
  })
  equal(newState.externalRssFeed.isDeleting, false)
})

test('DELETE_EXTERNAL_FEED_SUCCESS should delete feed from state', () => {
  const newState = reduce(actions.deleteExternalFeedSuccess({feedId: 12}), {
    externalRssFeed: {
      feeds: [
        {id: 12, title: 'Felix M'},
        {id: 34, title: 'Aaron H'},
        {id: 37, title: 'Steve B'},
      ],
    },
  })
  deepEqual(newState.externalRssFeed.feeds, [
    {id: 34, title: 'Aaron H'},
    {id: 37, title: 'Steve B'},
  ])
})

test('DELETE_EXTERNAL_FEED_FAIL should not delete feed', () => {
  const newState = reduce(actions.deleteExternalFeedFail({feedId: 12}), {
    externalRssFeed: {
      feeds: [
        {id: 12, title: 'Felix M'},
        {id: 34, title: 'Aaron H'},
        {id: 37, title: 'Steve B'},
      ],
    },
  })
  deepEqual(newState.externalRssFeed.feeds, [
    {id: 12, title: 'Felix M'},
    {id: 34, title: 'Aaron H'},
    {id: 37, title: 'Steve B'},
  ])
})
