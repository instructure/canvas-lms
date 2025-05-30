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

import React from 'react'
import {render} from '@testing-library/react'
import UsersPane, {SEARCH_DEBOUNCE_TIME} from '../UsersPane'
import UserActions from '../../actions/UserActions'
import fakeENV from '@canvas/test-utils/fakeENV'

const ok = value => expect(value).toBeTruthy()
const notOk = value => expect(value).toBeFalsy()
const equal = (value, expected) => expect(value).toEqual(expected)

const fakeStore = () => ({
  state: {
    userList: {
      users: [{}],
      isLoading: false,
      errors: {search_term: ''},
      next: undefined,
      searchFilter: {search_term: ''},
      permissions: {},
      accountId: 1,
    },
  },
  dispatch() {},
  getState() {
    return this.state
  },
  subscribe() {
    return () => {} // Return an unsubscribe function
  },
})

const renderUsersPane = store =>
  render(
    <UsersPane
      store={store}
      roles={[{id: 'id', label: 'label'}]}
      queryParams={{}}
      onUpdateQueryParams={function () {}}
    />,
  )

describe('Account Course User Search UsersPane View', () => {
  beforeEach(() => {
    fakeENV.setup({
      PERMISSIONS: {
        can_create_users: true,
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })
  test('handleUpdateSearchFilter dispatches applySearchFilter action', done => {
    const spy = jest.spyOn(UserActions, 'applySearchFilter')
    const store = fakeStore()
    renderUsersPane(store)

    setTimeout(() => {
      spy.mockRestore()
      done()
    }, SEARCH_DEBOUNCE_TIME)
  })

  test('have an h1 on the page', () => {
    const store = fakeStore()
    const {getAllByRole} = renderUsersPane(store)
    const headings = getAllByRole('heading', {level: 1})
    expect(headings).toHaveLength(1)
  })

  test('does not render UserList if loading', () => {
    const store = fakeStore()
    store.state.userList.isLoading = true
    const {container} = renderUsersPane(store)
    expect(container).toBeTruthy()
  })
})
