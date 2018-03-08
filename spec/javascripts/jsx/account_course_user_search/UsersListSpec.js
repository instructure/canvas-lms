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
import {shallow, mount} from 'enzyme'
import UsersList from 'jsx/account_course_user_search/components/UsersList'
import UsersListRow from 'jsx/account_course_user_search/components/UsersListRow'

QUnit.module('Account Course User Search UsersList View')

const usersProps = {
  accountId: '1',
  users: [
    {
      id: '1',
      name: 'UserA',
      avatar_url: 'http://someurl'
    },
    {
      id: '2',
      name: 'UserB',
      avatar_url: 'http://someurl'
    },
    {
      id: '3',
      name: 'UserC',
      avatar_url: 'http://someurl'
    }
  ],
  handlers: {
    handleOpenEditUserDialog() {},
    handleSubmitEditUserForm() {},
    handleCloseEditUserDialog() {}
  },
  permissions: {
    can_masquerade: true,
    can_message_users: true,
    can_edit_users: true
  },
  userList: {
    searchFilter: {
      search_term: 'User',
      sort: 'username',
      order: 'asc'
    }
  },
  onUpdateFilters: sinon.spy(),
  onApplyFilters: sinon.spy(),
  roles: {}
}

test('displays users that are passed in as props', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const renderedList = wrapper.find(UsersListRow)

  equal(renderedList.nodes[0].props.user.name, 'UserA')
  equal(renderedList.nodes[1].props.user.name, 'UserB')
  equal(renderedList.nodes[2].props.user.name, 'UserC')
})

Object.entries({
  username: 'Name',
  email: 'Email',
  sis_id: 'SIS ID',
  last_login: 'Last Login'
}).forEach(([columnID, label]) => {
  Object.entries({
    asc: {
      expectedArrow: 'Down',
      unexpectedArrow: 'Up',
      expectedTip: `Click to sort by ${label} descending`
    },
    desc: {
      expectedArrow: 'Up',
      unexpectedArrow: 'Down',
      expectedTip: `Click to sort by ${label} ascending`
    }
  }).forEach(([sortOrder, {expectedArrow, unexpectedArrow, expectedTip}]) => {
    const props = {
      ...usersProps,
      userList: {
        searchFilter: {
          search_term: 'User',
          sort: columnID,
          order: sortOrder
        }
      }
    }

    test(`sorting by ${columnID} ${sortOrder} puts ${expectedArrow}-arrow on ${label} only`, () => {
      const wrapper = mount(<UsersList {...props} />)
      equal(
        wrapper.find(`IconMiniArrow${unexpectedArrow}Solid`).length,
        0,
        `no columns have an ${unexpectedArrow} arrow`
      )
      const icons = wrapper.find(`IconMiniArrow${expectedArrow}Solid`)
      equal(icons.length, 1, `only one ${expectedArrow} arrow`)
      const header = icons.closest('UserListHeader')
      ok(
        header
          .find('ScreenReaderContent')
          .text()
          .match(RegExp(expectedTip, 'i')),
        'has right tooltip'
      )
      ok(header.text().includes(label), `${label} is the one that has the ${expectedArrow} arrow`)
    })

    test(`clicking the ${label} column header calls onChangeSort with ${columnID}`, function() {
      const sortSpy = this.spy()
      const wrapper = mount(
        <UsersList
          {...{
            ...props,
            onUpdateFilters: sortSpy
          }}
        />
      )
      const header = wrapper
        .find('UserListHeader')
        .filterWhere(n => n.text().includes(label))
        .find('button')
      header.simulate('click')
      ok(sortSpy.calledOnce)
      ok(
        sortSpy.calledWith({
          search_term: 'User',
          sort: columnID,
          order: sortOrder === 'asc' ? 'desc' : 'asc',
          role_filter_id: undefined
        })
      )
    })
  })
})
