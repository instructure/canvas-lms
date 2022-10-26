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
import {mount, shallow} from 'enzyme'

import {ROLES} from '../../__tests__/examples'
import RoleTrayTableRow from '../RoleTrayTableRow'

const MockedButton = () => <div className="mocked-permissionbutton" />
const MockedCheckbox = () => <input type="checkbox" className="mocked-permissioncheckbox" />

function createRowProps(title, roleId) {
  const role = ROLES.find(r => r.id === roleId)
  const permissionName = Object.keys(role.permissions)[0]
  const permission = role.permissions[permissionName]
  const permissionLabel = 'whatever'
  const onChange = Function.prototype

  permission.permissionLabel = 'test'
  return {title, role, permission, permissionName, permissionLabel, onChange}
}

it('renders the title', () => {
  const tree = shallow(<RoleTrayTableRow {...createRowProps('banana', '1')} />)
  const node = tree.find('Text')
  expect(node.exists()).toBeTruthy()
  expect(node.children().text()).toEqual('banana')
})

it('renders the expandable button if expandable prop is true', () => {
  const props = createRowProps('banana', '1')
  props.expandable = true
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('IconArrowOpenStartSolid')
  expect(node.exists()).toBeTruthy()
})

it('does not render the expandable button if expandable prop is false', () => {
  const props = createRowProps('banana', '1')
  props.expandable = false
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('IconArrowOpenStartSolid')
  expect(node.exists()).toBeFalsy()
})

it('renders the description if provided', () => {
  const props = createRowProps('banana', '1')
  props.description = "it's a fruit"
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('Text')
  expect(node).toHaveLength(2)
  expect(node.at(1).exists()).toBeTruthy()
  expect(node.at(1).children().text()).toEqual("it's a fruit")
})

it('does not render the description if not provided', () => {
  const props = createRowProps('banana', '1')
  props.description = ''
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('Text')
  expect(node).toHaveLength(1)
})

// From here on, we're doing a full tree render to test the granular permission
// logic, so we have to mock out the real PermissionButton and GranularCheckbox
// components to avoid it dragging in a bunch of Redux stuff that isn't going
// to be available in this test environment. Those components themselves are
// tested elsewhere.

const fakeButtons = {permButton: MockedButton, permCheckbox: MockedCheckbox}

it('renders a Permission Button for a "regular old" permission', () => {
  const props = createRowProps('banana', '1')
  const tree = mount(<RoleTrayTableRow {...props} {...fakeButtons} />)
  const node = tree.find('div.mocked-permissionbutton')
  expect(node).toHaveLength(1)
})

it('renders a checkbox for a granular permission', () => {
  const props = createRowProps('banana', '1')
  props.permission.group = 'group-permission-name'
  const tree = mount(<RoleTrayTableRow {...props} {...fakeButtons} />)
  const node = tree.find('input.mocked-permissioncheckbox')
  expect(node).toHaveLength(1)
})
