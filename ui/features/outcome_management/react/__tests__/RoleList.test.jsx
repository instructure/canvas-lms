/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, shallow} from 'enzyme'
import RoleList from '../RoleList'

const defaultProps = (props = {}) => ({
  description: 'My RoleList',
  roles: [
    {id: '26', role: 'Custom Admin', label: 'Custom Admin', base_role_type: 'AccountMembership'},
    {id: '1', role: 'AccountAdmin', label: 'Account Admin', base_role_type: 'AccountMembership'},
  ],
  ...props,
})

it('renders the RoleList component', () => {
  const list = shallow(<RoleList {...defaultProps()} />, {disableLifecycleMethods: true})
  expect(list.exists()).toBe(true)
})

it('renders description', () => {
  const list = render(<RoleList {...defaultProps()} />)
  expect(list.text()).toContain('My RoleList')
})

it('renders roles with account admin first', () => {
  const list = render(<RoleList {...defaultProps()} />)
  expect(list.text()).toContain('Account AdminCustom Admin')
})

it('does not renders description without roles', () => {
  const list = render(<RoleList {...defaultProps({roles: []})} />)
  expect(list.text()).not.toContain('My RoleList')
})
