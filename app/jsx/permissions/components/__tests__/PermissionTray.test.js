/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {ROLES} from '../../__tests__/examples'
import PermissionTray from '../PermissionTray'

function makeDefaultProps() {
  return {
    assignedRoles: ROLES.filter(r => r.id === '1'),
    label: 'Student',
    permissionName: 'add_section',
    open: true,
    hideTray: () => {},
    unassignedRoles: ROLES.filter(r => r.id === '2')
  }
}

it('renders the label', () => {
  const props = makeDefaultProps()
  const tree = shallow(<PermissionTray {...props} />)
  const node = tree.find('Heading')
  expect(node.exists()).toBeTruthy()
  expect(node.children().text()).toEqual('Student')
})

it('renders assigned roles if any are present', () => {
  const props = makeDefaultProps()
  props.unassignedRoles = []
  const tree = shallow(<PermissionTray {...props} />)
  const node = tree.find('RoleTrayTable')
  expect(node.exists()).toBeTruthy()
  expect(node.props().title).toEqual('Assigned Roles')
})

it('does not render assigned or unassigned roles if none are present', () => {
  const props = makeDefaultProps()
  props.assignedRoles = []
  props.unassignedRoles = []
  const tree = shallow(<PermissionTray {...props} />)
  const node = tree.find('RoleTrayTable')
  expect(node.exists()).toBeFalsy()
})

it('renders unassigned roles if any are present', () => {
  const props = makeDefaultProps()
  props.assignedRoles = []
  const tree = shallow(<PermissionTray {...props} />)
  const node = tree.find('RoleTrayTable')
  expect(node.exists()).toBeTruthy()
  expect(node.props().title).toEqual('Unassigned Roles')
})

it('renders details toggles for permissions if any are present', () => {
  const props = makeDefaultProps()
  props.permissionName = 'manage_account_settings'
  const tree = shallow(<PermissionTray {...props} />)
  const node = tree.find('DetailsToggle')
  expect(node.exists()).toBeTruthy()
})
