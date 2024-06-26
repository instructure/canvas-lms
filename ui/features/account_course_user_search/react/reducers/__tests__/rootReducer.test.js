/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import reducer from '../rootReducer'

describe('Account Course User Search Reducer', () => {
  test('ADD_ERROR action reducer', () => {
    const initialState = {
      userList: {
        users: [],
        errors: [],
      },
    }

    const action = {
      type: 'ADD_ERROR',
      error: {errorKey: 'test error'},
    }

    const newState = reducer(initialState, action)
    const errors = newState.userList.errors
    expect(errors.errorKey).toBe('test error')
  })

  test('ADD_TO_USERS action reducer', () => {
    const initialState = {
      userList: {
        users: [],
        isLoading: true,
        errors: {search_term: ''},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'ADD_TO_USERS',
      payload: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
      },
    }

    const newState = reducer(initialState, action)
    const user = newState.userList.users[0]

    expect(user.email).toBe('some_email@example.com')
  })

  test('ADD_TO_USERS action reducer invalid email', () => {
    const initialState = {
      userList: {
        users: [],
        isLoading: true,
        errors: {search_term: ''},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'ADD_TO_USERS',
      payload: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'invalid.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
      },
    }

    const newState = reducer(initialState, action)
    const user = newState.userList.users[0]

    expect(user.email).toBeUndefined()
  })

  test('GOT_USERS action reducer', () => {
    const initialState = {
      userList: {
        users: [],
        isLoading: true,
        errors: {search_term: ''},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const LinkHeader =
      '<http://canvas/api/v1/accounts/1/users?page=2>; rel="current",' +
      '<http://canvas/api/v1/accounts/1/users?page=3>; rel="next",' +
      '<http://canvas/api/v1/accounts/1/users?page=1>; rel="prev",' +
      '<http://canvas/api/v1/accounts/1/users?page=1>; rel="first",' +
      '<http://canvas/api/v1/accounts/1/users?page=5>; rel="last"'

    const parsedLinkHeader = {
      current: {page: '2', rel: 'current', url: 'http://canvas/api/v1/accounts/1/users?page=2'},
      next: {page: '3', rel: 'next', url: 'http://canvas/api/v1/accounts/1/users?page=3'},
      prev: {page: '1', rel: 'prev', url: 'http://canvas/api/v1/accounts/1/users?page=1'},
      first: {page: '1', rel: 'first', url: 'http://canvas/api/v1/accounts/1/users?page=1'},
      last: {page: '5', rel: 'last', url: 'http://canvas/api/v1/accounts/1/users?page=5'},
    }

    const action = {
      type: 'GOT_USERS',
      payload: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
        xhr: {
          getResponseHeader: jest.fn().mockReturnValue(LinkHeader),
        },
      },
    }

    const newState = reducer(initialState, action)
    expect(newState.userList.links).toEqual(parsedLinkHeader)
    expect(newState.userList.isLoading).toBe(false)
    expect(newState.userList.users).toEqual(action.payload.users)
  })

  test('GOT_USER_UPDATE action reducer', () => {
    const initialState = {
      userList: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
        isLoading: true,
        errors: {search_term: ''},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'GOT_USER_UPDATE',
      payload: {
        id: '1',
        name: 'aNewName',
      },
    }

    const newState = reducer(initialState, action)
    expect(newState.userList.users[0]).toEqual(action.payload)
  })

  test('OPEN_EDIT_USER_DIALOG action reducer', () => {
    const initialState = {
      userList: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
        isLoading: true,
        errors: {search_term: ''},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'OPEN_EDIT_USER_DIALOG',
      payload: {
        id: '1',
        name: 'aNewName',
      },
    }

    const newState = reducer(initialState, action)
    expect(newState.userList.users[0].editUserDialogOpen).toBe(true)
  })

  test('CLOSE_EDIT_USER_DIALOG action reducer', () => {
    const initialState = {
      userList: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
            editUserDialogOpen: true,
          },
        ],
        isLoading: true,
        errors: {search_term: ''},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'CLOSE_EDIT_USER_DIALOG',
      payload: {
        id: '1',
        name: 'aNewName',
      },
    }

    const newState = reducer(initialState, action)
    expect(newState.userList.users[0].editUserDialogOpen).toBe(false)
  })

  test('UPDATE_SEARCH_FILTER action reducer', () => {
    const initialState = {
      userList: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
        isLoading: true,
        errors: {},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'UPDATE_SEARCH_FILTER',
      payload: {
        search_term: 'someuser',
      },
    }

    const newState = reducer(initialState, action)
    expect(newState.userList.searchFilter.search_term).toBe(action.payload.search_term)
    expect(newState.userList.errors.search_term).toBe('')
  })

  test('LOADING_USERS action reducer', () => {
    const initialState = {
      userList: {
        users: [
          {
            id: '1',
            locale: null,
            login_id: 'some_email@example.com',
            name: 'someuser',
            short_name: 'someuser',
            sortable_name: 'someuser',
          },
        ],
        isLoading: false,
        errors: {},
        links: undefined,
        searchFilter: {search_term: ''},
        permissions: [],
        accountId: '123',
      },
    }

    const action = {
      type: 'LOADING_USERS',
      payload: {},
    }

    const newState = reducer(initialState, action)
    expect(newState.userList.isLoading).toBe(true)
  })

  test('SELECT_TAB action reducer', () => {
    const initialState = {
      tabList: {
        basePath: '/accounts/1/search',
        tabs: [
          {
            title: 'Tab1',
            path: '/courses',
            permisssions: [],
          },
          {
            title: 'Tab2',
            path: '/courses',
            permisssions: [],
          },
        ],
        selected: 0,
      },
    }

    const action = {
      type: 'SELECT_TAB',
      payload: {
        selected: 1,
      },
    }

    const newState = reducer(initialState, action)
    expect(newState.tabList.selected).toBe(1)
  })
})
