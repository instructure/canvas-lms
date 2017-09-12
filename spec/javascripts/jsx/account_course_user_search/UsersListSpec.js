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
import {shallow} from 'enzyme'
import UsersList from 'jsx/account_course_user_search/UsersList'
import UsersListRow from 'jsx/account_course_user_search/UsersListRow'

QUnit.module('Account Course User Search UsersList View');

const usersProps = {
  accountId: '1',
  users: [{
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
  }],
  handlers: {
    handleOpenEditUserDialog () {},
    handleSubmitEditUserForm () {},
    handleCloseEditUserDialog () {}
  },
  permissions: {
    can_masquerade: true,
    can_message_users: true,
    can_edit_users: true
  },
  timezones: {
    timezones: ['123123123'],
    priority_zones: ['alsdkfjasldkfjs']
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
};

test('displays users that are passed in as props', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const renderedList = wrapper.find(UsersListRow)

  equal(renderedList.nodes[0].props.user.name, 'UserA')
  equal(renderedList.nodes[1].props.user.name, 'UserB')
  equal(renderedList.nodes[2].props.user.name, 'UserC')
});

test('sorting by username ascending puts down-arrow on Name', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const header = wrapper.find('a').first()
  equal(header.nodes[0].props.children.props.children[1].type.name, 'IconArrowDownSolid')
});

test('clicking the Name column header calls onUpdateFilters with username descending', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const header = wrapper.find('a').first()
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onUpdateFilters
  ok(sinonCallback.calledOnce)
  ok(sinonCallback.calledWith({search_term: 'User', sort: 'username', order: 'desc'}))
});

test('clicking the Email column header calls onUpdateFilters with email ascending', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const header = wrapper.find('a').slice(1, 2)
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onUpdateFilters
  ok(sinonCallback.callCount === 2)
  ok(sinonCallback.calledWith({search_term: 'User', sort: 'email', order: 'asc'}))
});

test('clicking the SIS ID column header calls onUpdateFilters with sis_id ascending', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const header = wrapper.find('a').slice(2, 3)
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onUpdateFilters
  ok(sinonCallback.callCount === 3)
  ok(sinonCallback.calledWith({search_term: 'User', sort: 'sis_id', order: 'asc'}))
});

test('clicking the Last Login column header calls onUpdateFilters with last_login ascending', () => {
  const wrapper = shallow(<UsersList {...usersProps} />)
  const header = wrapper.find('a').slice(3, 4)
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onUpdateFilters
  ok(sinonCallback.callCount === 4)
  ok(sinonCallback.calledWith({search_term: 'User', sort: 'last_login', order: 'asc'}))
});
