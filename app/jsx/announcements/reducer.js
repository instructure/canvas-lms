/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import { combineReducers } from 'redux'
import { handleActions } from 'redux-actions'
import { actionTypes } from './actions'
import { reduceNotifications } from '../shared/reduxNotifications'
import { createPaginatedReducer } from '../shared/reduxPagination'

const MIN_SEATCH_LENGTH = 3

const identity = (defaultState = null) => (
  state => (state === undefined ? defaultState : state)
)

const reduceAnnouncementsPagination = createPaginatedReducer('announcements')

const reduceItems = handleActions({
  [actionTypes.LOCK_ANNOUNCEMENTS_SUCCESS]: (state, action) => {
    const successIds = action.payload.res.successes.map(success => success.data)
    return state.map(item => {
      return successIds.includes(item.id)
      ? ({ ...item, locked: action.payload.locked })
      : item
    })
  },
}, [])

function reducePage (page = {}, action) {
  return ({ ...page, items: reduceItems(page.items, action) })
}

function reduceCurrentPage (currentPage) {
  return (announcements = {}, action) =>
    ({
      ...announcements,
      pages: {
        ...announcements.pages,
        [currentPage]: reducePage(announcements.pages[currentPage], action),
      },
    })
}

function reduceAnnouncements (announcements, action) {
  const { currentPage, pages } = announcements
  let newState = { ...announcements }

  if (currentPage && pages && pages[currentPage]) {
    newState = reduceCurrentPage(currentPage)(announcements, action)
  }

  return newState
}

export default combineReducers({
  courseId: identity(null),
  permissions: identity({}),
  masterCourseData: identity(null),
  atomFeedUrl: identity(null),
  announcements: (state, action) => {
    const paginatedState = reduceAnnouncementsPagination(state, action)
    const newState = reduceAnnouncements(paginatedState, action)
    return newState
  },
  announcementsSearch: combineReducers({
    term: handleActions({
      [actionTypes.UPDATE_ANNOUNCEMENTS_SEARCH]: (state, action) => {
        const term = action.payload && action.payload.term
        if (term === undefined) {
          return state
        } else if (term.length < MIN_SEATCH_LENGTH) {
          return ''
        } else {
          return term
        }
      }
    }, ''),
    filter: handleActions({
      [actionTypes.UPDATE_ANNOUNCEMENTS_SEARCH]: (state, action) => {
        const filter = action.payload && action.payload.filter
        if (filter === undefined) {
          return state
        } else {
          return filter
        }
      }
    }, 'all'),
  }),
  selectedAnnouncements: handleActions({
    [actionTypes.SET_ANNOUNCEMENT_SELECTION]: (state, action) => {
      if (action.payload.selected) {
        // use of Set ensures we don't have duplicates
        return Array.from(new Set([...state, action.payload.id]))
      } else {
        const set = new Set(state)
        set.delete(action.payload.id)
        return Array.from(set)
      }
    },
    [actionTypes.CLEAR_ANNOUNCEMENT_SELECTIONS]: () => [],
    [actionTypes.DELETE_ANNOUNCEMENTS_SUCCESS]: () => [],
  }, []),
  isLockingAnnouncements: handleActions({
    [actionTypes.LOCK_ANNOUNCEMENTS_START]: () => true,
    [actionTypes.LOCK_ANNOUNCEMENTS_SUCCESS]: () => false,
    [actionTypes.LOCK_ANNOUNCEMENTS_FAIL]: () => false,
  }, false),
  isDeletingAnnouncements: handleActions({
    [actionTypes.DELETE_ANNOUNCEMENTS_START]: () => true,
    [actionTypes.DELETE_ANNOUNCEMENTS_SUCCESS]: () => false,
    [actionTypes.DELETE_ANNOUNCEMENTS_FAIL]: () => false,
  }, false),
  notifications: reduceNotifications,
})
