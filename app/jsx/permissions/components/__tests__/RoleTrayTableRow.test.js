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
import {shallow} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'

import {ROLES} from '../../__tests__/examples'
import RoleTrayTableRow from '../RoleTrayTableRow'

function createRowProps(title, roleId) {
  const role = ROLES.find(r => r.id === roleId)
  const permissionName = Object.keys(role.permissions)[0]
  const permission = role.permissions[permissionName]
  return {title, role, permission, permissionName}
}

it('renders the title', () => {
  const tree = shallow(<RoleTrayTableRow {...createRowProps('banana', '1')} />)
  const node = tree.find('Text')
  expect(node.exists()).toBeTruthy()
  expect(
    node
      .at(0)
      .dive()
      .text()
  ).toEqual('banana')
})

it('renders the expandable button if expandable prop is true', () => {
  const props = createRowProps('banana', '1')
  props.expandable = true
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('IconArrowOpenStart')
  expect(node.exists()).toBeTruthy()
})

it('does not render the expandable button if expandable prop is false', () => {
  const props = createRowProps('banana', '1')
  props.expandable = false
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('IconArrowOpenStart')
  expect(node.exists()).toBeFalsy()
})

it('renders the description if provided', () => {
  const props = createRowProps('banana', '1')
  props.description = "it's a fruit"
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('Text')
  expect(node).toHaveLength(2)
  expect(node.at(1).exists()).toBeTruthy()
  expect(
    node
      .at(1)
      .dive()
      .text()
  ).toEqual("it's a fruit")
})

it('does not render the description if not provided', () => {
  const props = createRowProps('banana', '1')
  props.description = ''
  const tree = shallow(<RoleTrayTableRow {...props} />)
  const node = tree.find('Text')
  expect(node).toHaveLength(1)
})
