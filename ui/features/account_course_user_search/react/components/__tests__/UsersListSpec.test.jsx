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

import React from 'react'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import UsersList from '../UsersList'
import fetchMock from 'fetch-mock'

describe('Account Course User Search UsersList View', function () {
  beforeEach(() => {
    fetchMock.mock(
      '/api/v1/users/1/enrollments?state%5B%5D=active&state%5B%5D=invited&temporary_enrollment_providers=true',
      {
        status: 200,
        body: {},
      },
    )
  })

  afterEach(() => {
    fetchMock.restore()
  })

  const usersProps = {
    accountId: '1',
    users: [
      {
        id: '1',
        name: 'UserA',
        short_name: 'UserA',
        sortable_name: 'UserA',
        avatar_url: 'http://someurl',
      },
      {
        id: '2',
        name: 'UserB',
        short_name: 'UserB',
        sortable_name: 'UserB',
        avatar_url: 'http://someurl',
      },
      {
        id: '3',
        name: 'UserC',
        short_name: 'UserC',
        sortable_name: 'UserC',
        avatar_url: 'http://someurl',
      },
    ],
    handleSubmitEditUserForm: jest.fn(),
    permissions: {
      can_masquerade: true,
      can_message_users: true,
      can_edit_users: true,
    },
    searchFilter: {
      search_term: 'User',
      sort: 'username',
      order: 'asc',
    },
    onUpdateFilters: jest.fn(),
    onApplyFilters: jest.fn(),
    sortColumnHeaderRef: jest.fn(),
    roles: [],
  }

  it('displays users that are passed in as props', () => {
    const {getByText} = render(<UsersList {...usersProps} />)

    expect(getByText('UserA')).toBeInTheDocument()
    expect(getByText('UserB')).toBeInTheDocument()
    expect(getByText('UserC')).toBeInTheDocument()
  })

  Object.entries({
    username: 'Name',
    email: 'Email',
    sis_id: 'SIS ID',
    last_login: 'Last Login',
  }).forEach(([columnID, label]) => {
    Object.entries({
      asc: {
        expectedArrow: 'Up',
        unexpectedArrow: 'Down',
        expectedTip: `Click to sort by ${label} descending`,
      },
      desc: {
        expectedArrow: 'Down',
        unexpectedArrow: 'Up',
        expectedTip: `Click to sort by ${label} ascending`,
      },
    }).forEach(([sortOrder, {expectedArrow, unexpectedArrow, expectedTip}]) => {
      const props = {
        ...usersProps,
        searchFilter: {
          search_term: 'User',
          sort: columnID,
          order: sortOrder,
        },
      }

      it(`sorting by ${columnID} ${sortOrder} puts ${expectedArrow}-arrow on ${label} only`, () => {
        const wrapper = render(<UsersList {...props} />)
        expect(
          wrapper.container.querySelectorAll(`[name="IconMiniArrow${unexpectedArrow}"]`),
        ).toHaveLength(0)
        const icons = wrapper.container.querySelectorAll(`[name="IconMiniArrow${expectedArrow}"]`)
        expect(icons).toHaveLength(1)
        const header = icons[0].closest('[data-testid="UsersListHeader"]')
        header.focus()
        expect(wrapper.queryAllByText(expectedTip)).toBeTruthy()
        expect(header.textContent.includes(label)).toBeTruthy()
      })

      it(`clicking the ${label} column header calls onChangeSort with ${columnID}`, async () => {
        const sortSpy = jest.fn()
        const wrapper = render(
          <UsersList
            {...{
              ...props,
              onUpdateFilters: sortSpy,
            }}
          />,
        )
        const header = Array.from(
          wrapper.container.querySelectorAll('[data-testid="UsersListHeader"]'),
        )
          .filter(n => n.textContent.includes(label))[0]
          .querySelector('button')
        const user = userEvent.setup({delay: null})
        await user.click(header)
        expect(sortSpy).toHaveBeenCalledTimes(1)
        expect(sortSpy).toHaveBeenCalledWith({
          search_term: 'User',
          sort: columnID,
          order: sortOrder === 'asc' ? 'desc' : 'asc',
          role_filter_id: undefined,
        })
      })
    })
  })
})
