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

import '@instructure/canvas-theme'
import React from 'react'
import {shallow} from 'enzyme'
import PermissionsTable from '../PermissionsTable'

import {COURSE, ENABLED_FOR_ALL} from '@canvas/permissions/react/propTypes'

const defaultProps = () => ({
  roles: [
    {
      id: '1',
      label: 'Role 1',
      base_role_type: 'lead',
      permissions: {
        permission_1: 'permission_1',
        permission_2: 'permission_2',
      },
      displayed: true,
    },
    {
      id: '2',
      label: 'Role 2',
      base_role_type: 'lead',
      permissions: {
        permission_1: 'permission_1',
        permission_2: 'permission_2',
      },
      displayed: true,
    },
  ],
  modifyPermissions: () => {},
  setAndOpenRoleTray: () => {},
  setAndOpenPermissionTray: () => {},
  permissions: [
    {permission_name: 'permission_1', label: 'Permission 1', contextType: COURSE, displayed: true},
    {permission_name: 'permission_2', label: 'Permission 2', contextType: COURSE, displayed: true},
  ],
})

const granularPermissionProps = () => ({
  roles: [
    {
      id: '1',
      label: 'Role 1',
      base_role_type: 'lead',
      permissions: {
        granular_1: {
          enabled: ENABLED_FOR_ALL,
          explicit: true,
          group: 'granular_permission_group',
          locked: false,
          readonly: false,
        },
        granular_2: {
          enabled: ENABLED_FOR_ALL,
          explicit: true,
          group: 'granular_permission_group',
          locked: false,
          readonly: false,
        },
        granular_permission_group: {
          built_from_granular_permissions: true,
          enabled: ENABLED_FOR_ALL,
          explicit: true,
          locked: false,
          readonly: false,
        },
      },
      displayed: true,
    },
  ],
  modifyPermissions: () => {},
  setAndOpenRoleTray: () => {},
  setAndOpenPermissionTray: () => {},
  permissions: [
    {
      permission_name: 'granular_permission_group',
      label: 'Grouped Granular Permission',
      contextType: COURSE,
      displayed: true,
      granular_permissions: [
        {
          permission_name: 'granular_1',
          label: 'Granular 1',
          granular_permission_group: 'granular_permission_group',
          granular_permission_group_label: 'Grouped Permission Label',
        },
        {
          permission_name: 'granular_2',
          label: 'Granular 2',
          granular_permission_group: 'granular_permission_group',
          granular_permission_group_label: 'Grouped Permission Label',
        },
      ],
    },
  ],
})

it('calls setAndOpenRoleTray on clicking one of the top headers', () => {
  const setAndOpenRoleTrayMock = jest.fn()
  const props = defaultProps()
  props.setAndOpenRoleTray = setAndOpenRoleTrayMock

  const tree = shallow(<PermissionsTable {...props} />)
  const node = tree.find('#role_1')
  expect(node).toHaveLength(1)
  node.at(0).simulate('click')
  expect(setAndOpenRoleTrayMock).toHaveBeenCalledWith(props.roles[0])
})

it('calls setAndOpenPermissionTray on clicking one of the side headers', () => {
  const setAndOpenPermissionTrayMock = jest.fn()
  const props = defaultProps()
  props.setAndOpenPermissionTray = setAndOpenPermissionTrayMock

  const tree = shallow(<PermissionsTable {...props} />)
  const node = tree.find('#permission_permission_1')
  expect(node).toHaveLength(1)
  node.at(0).simulate('click')
  expect(setAndOpenPermissionTrayMock).toHaveBeenCalledWith(props.permissions[0])
})

it('displays granular permissions when the expand button is pressed', () => {
  const props = granularPermissionProps()
  const tree = shallow(<PermissionsTable {...props} />)
  const expand_button = tree.find('[data-testid="expand_granular_permission_group"]')
  expect(expand_button).toHaveLength(1)
  expand_button.at(0).simulate('click')

  const table_permissions = tree.find('.ic-permissions__left-header__col-wrapper')
  expect(table_permissions).toHaveLength(3)

  const button1 = table_permissions.at(0)
  const button2 = table_permissions.at(1)
  const button3 = table_permissions.at(2)

  // Rendering the expand button and the permission name here, why it looks wierd
  expect(button1.render().text()).toEqual(
    'Expand Grouped Granular PermissionGrouped Granular Permission'
  )
  expect(button2.render().text()).toEqual('Granular 1')
  expect(button3.render().text()).toEqual('Granular 2')
})
