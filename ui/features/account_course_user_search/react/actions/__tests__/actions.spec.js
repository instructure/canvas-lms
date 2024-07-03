/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import actions from '../UserActions'

const STUDENTS = [
  {
    id: '46',
    name: 'Irene Adler',
    sortable_name: 'Adler, Irene',
    short_name: 'Irene Adler',
    sis_user_id: '957',
    integration_id: null,
    sis_login_id: 'student57',
    sis_import_id: '1',
    login_id: 'student57',
    email: 'brotherhood@example.com',
    last_login: null,
    time_zone: 'Mountain Time (US & Canada)',
  },
  {
    id: '44',
    name: 'Saint-John Allerdyce',
    sortable_name: 'Allerdyce, Saint-John',
    short_name: 'Saint-John Allerdyce',
    sis_user_id: '955',
    integration_id: null,
    sis_login_id: 'student55',
    sis_import_id: '1',
    login_id: 'student55',
    email: 'brotherhood@example.com',
    last_login: null,
    time_zone: 'Mountain Time (US & Canada)',
  },
  {
    id: '52',
    name: 'Michael Baer',
    sortable_name: 'Baer, Michael',
    short_name: 'Michael Baer',
    sis_user_id: '963',
    integration_id: null,
    sis_login_id: 'student63',
    sis_import_id: '1',
    login_id: 'student63',
    email: 'marauders@example.com',
    last_login: null,
    time_zone: 'Mountain Time (US & Canada)',
  },
]

describe('Account Course User Search Actions', () => {
  test('updateSearchFilter', () => {
    const message = actions.updateSearchFilter('myFilter')
    expect(message.type).toBe('UPDATE_SEARCH_FILTER')
    expect(message.payload).toBe('myFilter')
  })

  test('displaySearchTermTooShortError', () => {
    const message = actions.displaySearchTermTooShortError(3)
    expect(message.type).toBe('SEARCH_TERM_TOO_SHORT')
    expect(message.errors.termTooShort).toBe('Search term must be at least 3 characters')
  })

  test('loadingUsers', () => {
    const message = actions.loadingUsers()
    expect(message.type).toBe('LOADING_USERS')
  })

  test('applySearchFilter', async () => {
    let count = 3
    const done = () => {
      --count
    }

    const fakeDispatcherSearchLengthOkay = response => {
      if (count === 3) {
        expect(response.type).toBe('LOADING_USERS')
        done()
      } else {
        expect(response.type).toBe('GOT_USERS')
        expect(response.payload.users[0]).toEqual(STUDENTS[0])
        done()
      }
    }

    const fakeGetStateSearchLengthOkay = () => ({
      userList: {
        searchFilter: {
          search_term: 'abcd',
        },
      },
    })

    const fakeDispatcherSearchLengthTooShort = response => {
      expect(response.type).toBe('SEARCH_TERM_TOO_SHORT')
      expect(response.errors.termTooShort).toBe('Search term must be at least 4 characters')
      done()
    }

    const fakeGetStateSearchLengthTooShort = () => ({
      userList: {
        searchFilter: {
          search_term: 'a',
        },
      },
    })

    const fakeUserStore = {
      load() {
        return Promise.resolve([STUDENTS[0]])
      },
    }

    const actionThunk = actions.applySearchFilter(4, fakeUserStore)

    expect(typeof actionThunk).toBe('function')

    await actionThunk(fakeDispatcherSearchLengthOkay, fakeGetStateSearchLengthOkay)
    await actionThunk(fakeDispatcherSearchLengthTooShort, fakeGetStateSearchLengthTooShort)
  })
})
