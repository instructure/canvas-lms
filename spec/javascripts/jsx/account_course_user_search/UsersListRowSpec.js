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
import UsersListRow from 'jsx/account_course_user_search/UsersListRow'

QUnit.module('Account Course User Search UsersListRow View')

const defaultProps = () => ({
  user: {
    id: '1',
    name: 'foo',
    avatar_url: 'http://someurl'
  },
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
  timezones: {
    timezones: [{name: '123123123', localized_name: '123123123 localized'}],
    priority_zones: [{name: 'alsdkfjasldkfjs', localized_name: 'alsk localized'}]
  }
})

test('renders an avatar when needed', () => {
  const wrapper = shallow(<UsersListRow {...defaultProps()} />)
  ok(
    wrapper.find('.ic-avatar').exists(),
    'avatar is rendered when supplied given user.avatar_url prop'
  )

  const propsWithNoAvatar = defaultProps()
  propsWithNoAvatar.user.avatar_url = null
  const wrapperWithNoAvatar = shallow(<UsersListRow {...propsWithNoAvatar} />)
  notOk(wrapperWithNoAvatar.find('.ic-avatar').exists(), 'the avatar is not rendered')
})

test('renders all actions when all permissions are present', () => {
  const wrapper = shallow(<UsersListRow {...defaultProps()} />)
  equal(wrapper.find('.courses-user-list-actions Button').length, 3)
})

test('renders no actions if no permissions are present', () => {
  const propsWithNoPermissions = {
    ...defaultProps(),
    permissions: {
      can_masquerade: false,
      can_message_users: false,
      can_edit_users: false
    }
  }
  const wrapper = shallow(<UsersListRow {...propsWithNoPermissions} />)
  equal(wrapper.find('.courses-user-list-actions Button').length, 0)
})
