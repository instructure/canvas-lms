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

import reducer from 'jsx/account_course_user_search/reducers/rootReducer'

QUnit.module('Account Course User Search Reducer')

test('ADD_ERROR action reducer', () => {
  const initialState = {
    userList: {
      users: [],
      errors: []
    }
  }

  const action = {
    type: 'ADD_ERROR',
    error: {errorKey: 'test error'}
  }

  const newState = reducer(initialState, action)
  const errors = newState.userList.errors
  equal(errors.errorKey, 'test error', 'sets the errors property')
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
      accountId: '123'
    }
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
          sortable_name: 'someuser'
        }
      ]
    }
  }

  const newState = reducer(initialState, action)
  const user = newState.userList.users[0]

  equal(user.email, 'some_email@example.com', 'creates an email property if needed')
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
      accountId: '123'
    }
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
          sortable_name: 'someuser'
        }
      ]
    }
  }

  const newState = reducer(initialState, action)
  const user = newState.userList.users[0]

  equal(user.email, null, 'creates an email property if needed')
})

test('GOT_USERS action reducer', function() {
  const initialState = {
    userList: {
      users: [],
      isLoading: true,
      errors: {search_term: ''},
      links: undefined,
      searchFilter: {search_term: ''},
      permissions: [],
      accountId: '123'
    }
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
    last: {page: '5', rel: 'last', url: 'http://canvas/api/v1/accounts/1/users?page=5'}
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
          sortable_name: 'someuser'
        }
      ],
      xhr: {
        getResponseHeader: sandbox.mock()
          .withArgs('Link')
          .returns(LinkHeader)
      }
    }
  }

  const newState = reducer(initialState, action)
  deepEqual(newState.userList.links, parsedLinkHeader, 'sets the links property')
  equal(newState.userList.isLoading, false, 'sets the isLoading property to false')
  equal(newState.userList.users, action.payload.users, 'set the users property.')
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
          sortable_name: 'someuser'
        }
      ],
      isLoading: true,
      errors: {search_term: ''},
      links: undefined,
      searchFilter: {search_term: ''},
      permissions: [],
      accountId: '123'
    }
  }
  const action = {
    type: 'GOT_USER_UPDATE',
    payload: {
      id: '1',
      name: 'aNewName'
    }
  }

  const newState = reducer(initialState, action)
  deepEqual(newState.userList.users[0], action.payload, 'sets the user to the updated user')
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
          sortable_name: 'someuser'
        }
      ],
      isLoading: true,
      errors: {search_term: ''},
      links: undefined,
      searchFilter: {search_term: ''},
      permissions: [],
      accountId: '123'
    }
  }
  const action = {
    type: 'OPEN_EDIT_USER_DIALOG',
    payload: {
      id: '1',
      name: 'aNewName'
    }
  }

  const newState = reducer(initialState, action)
  equal(
    newState.userList.users[0].editUserDialogOpen,
    true,
    'sets the open dialog property on the user'
  )
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
          editUserDialogOpen: true
        }
      ],
      isLoading: true,
      errors: {search_term: ''},
      links: undefined,
      searchFilter: {search_term: ''},
      permissions: [],
      accountId: '123'
    }
  }
  const action = {
    type: 'CLOSE_EDIT_USER_DIALOG',
    payload: {
      id: '1',
      name: 'aNewName'
    }
  }

  const newState = reducer(initialState, action)
  equal(
    newState.userList.users[0].editUserDialogOpen,
    false,
    'sets the open dialog property on the user to false'
  )
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
          sortable_name: 'someuser'
        }
      ],
      isLoading: true,
      errors: {},
      links: undefined,
      searchFilter: {search_term: ''},
      permissions: [],
      accountId: '123'
    }
  }
  const action = {
    type: 'UPDATE_SEARCH_FILTER',
    payload: {
      search_term: 'someuser'
    }
  }

  const newState = reducer(initialState, action)
  equal(
    newState.userList.searchFilter.search_term,
    action.payload.search_term,
    'sets the search term property'
  )
  equal(newState.userList.errors.search_term, '', 'sets the error for search term to empty string')
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
          sortable_name: 'someuser'
        }
      ],
      isLoading: false,
      errors: {},
      links: undefined,
      searchFilter: {search_term: ''},
      permissions: [],
      accountId: '123'
    }
  }
  const action = {
    type: 'LOADING_USERS',
    payload: {}
  }

  const newState = reducer(initialState, action)
  equal(newState.userList.isLoading, true, 'sets the loading property to true')
})

test('SELECT_TAB action reducer', () => {
  const initialState = {
    tabList: {
      basePath: '/accounts/1/search',
      tabs: [
        {
          title: 'Tab1',
          path: '/courses',
          permisssions: []
        },
        {
          title: 'Tab2',
          path: '/courses',
          permisssions: []
        }
      ],
      selected: 0
    }
  }
  const action = {
    type: 'SELECT_TAB',
    payload: {
      selected: 1
    }
  }

  const newState = reducer(initialState, action)
  equal(newState.tabList.selected, 1, 'sets the selected tab property to 1')
})
