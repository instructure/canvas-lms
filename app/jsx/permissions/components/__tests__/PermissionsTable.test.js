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

import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import {Provider} from 'react-redux'
import {mount} from 'enzyme'
import PermissionsTable from '../PermissionsTable'

import {COURSE} from '../../propTypes'

const defaultProps = () => ({
  roles: [
    {
      id: '1',
      label: 'Role 1',
      permissions: {permission_1: 'permission_1', permission_2: 'permission_2'},
      displayed: true
    },
    {
      id: '2',
      label: 'Role 2',
      permissions: {permission_1: 'permission_1', permission_2: 'permission_2'},
      displayed: true
    }
  ],
  setAndOpenRoleTray: () => {},
  setAndOpenPermissionTray: () => {},
  permissions: [
    {permission_name: 'permission_1', label: 'Permission 1', contextType: COURSE, displayed: true},
    {permission_name: 'permission_2', label: 'Permission 2', contextType: COURSE, displayed: true}
  ]
})

const store = {
  getState: () => ({
    contextId: 1,
    permissions: [],
    roles: []
  }),
  dispatch() {},
  subscribe() {}
}

it('renders the Permissions Table', () => {
  const tree = mount(
    <Provider store={store}>
      <PermissionsTable {...defaultProps()} />
    </Provider>
  )
  const node = tree.find('PermissionsTable')
  expect(node.exists()).toBe(true)
})

// TODO: add more once we get something more fleshed out
