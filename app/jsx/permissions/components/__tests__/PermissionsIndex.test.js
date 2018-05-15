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
import {mount} from 'enzyme'

import PermissionsIndex from 'jsx/permissions/components/PermissionsIndex'

const defaultProps = () => ({
  contextId: 1,
  accountPermissions: [{permission_name: 'account_permission', label: 'account permission'}],
  coursePermissions: [{permission_name: 'course_permission', label: 'course permission'}],
  accountRoles: [],
  courseRoles: []
})

test('renders the component', () => {
  const tree = mount(<PermissionsIndex {...defaultProps()} />)
  const node = tree.find('PermissionsIndex')
  expect(node.exists()).toBe(true)
})

test('renders course and accounts tab', () => {
  const tree = mount(<PermissionsIndex {...defaultProps()} />)
  const node = tree.find('TabPanel')
  expect(node).toHaveLength(2)
  const firstTab = node.nodes[0]
  const secondTab = node.nodes[1]
  expect(firstTab.props.title.includes('Course Roles')).toBe(true)
  expect(secondTab.props.title.includes('Account Roles')).toBe(true)
})

test('Renders course permissions table by default', () => {
  const tree = mount(<PermissionsIndex {...defaultProps()} />)
  tree.render()
  expect(
    tree
      .find('tr')
      .at(1)
      .text()
      .includes('course permission')
  ).toBe(true)
  expect(
    tree
      .find('tr')
      .at(1)
      .text()
      .includes('account permission')
  ).toBe(false)
})

// TODO(COMMS-1122): Get specs up that test switching tabs works
