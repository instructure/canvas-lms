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
import {shallow} from 'enzyme'
import UsersPane, {
  SEARCH_DEBOUNCE_TIME,
} from 'ui/features/account_course_user_search/react/components/UsersPane'
import UserActions from 'ui/features/account_course_user_search/react/actions/UserActions'

QUnit.module('Account Course User Search UsersPane View')

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
  subscribe() {},
})

const wrapper = store =>
  shallow(
    <UsersPane store={store} roles={['a']} queryParams={{}} onUpdateQueryParams={function () {}} />
  )

test('handleUpdateSearchFilter dispatches applySearchFilter action', assert => {
  const done = assert.async()
  const spy = sinon.spy(UserActions, 'applySearchFilter')
  const store = fakeStore()
  const instance = wrapper(store).instance()
  instance.handleUpdateSearchFilter()
  setTimeout(() => {
    ok(spy.called)
    done()
  }, SEARCH_DEBOUNCE_TIME)
})

test('have an h1 on the page', () => {
  const store = fakeStore()
  equal(wrapper(store).find('h1').length, 1, 'There is one H1 on the page')
})

test('does not render UserList if loading', () => {
  const store = fakeStore()
  store.state.userList.isLoading = true
  notOk(wrapper(store).find('UsersList').exists())
})
