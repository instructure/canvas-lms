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

import {getPermissionsWithLabels} from '../../helper/utils'
import {ROLES, PERMISSIONS} from '../../__tests__/examples'
import RoleTray from '../RoleTray'

function makeDefaultProps() {
  const role = ROLES[0]
  const perms = getPermissionsWithLabels(PERMISSIONS, role.permissions)
  return {
    assignedPermissions: perms,
    id: '1',
    assignedTo: '365',
    basedOn: null,
    updateRoleNameAndBaseType: () => {},
    baseRoleLabels: ['Student', 'Teacher', 'TA'],
    changedBy: 'Bob Dobbs',
    deletable: false,
    editable: false,
    hideTray: () => {},
    label: 'Student',
    lastChanged: '1/1/1970',
    open: true,
    role,
    unassignedPermissions: perms
  }
}

it('renders the component', () => {
  const props = makeDefaultProps()
  const tree = mount(<RoleTray {...props} />)
  const node = tree.find('RoleTray')
  expect(node.exists()).toBeTruthy()
})

it('renders assigned permissions if any are present', () => {
  const props = makeDefaultProps()
  props.unassignedPermissions = []
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('RoleTrayTable')
  expect(node.exists()).toBeTruthy()
  expect(node.props().title).toEqual('Assigned Permissions')
})

it('does not render assigned or unassigned permissions if none are present', () => {
  const props = makeDefaultProps()
  props.assignedPermissions = []
  props.unassignedPermissions = []
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('RoleTrayTable')
  expect(node.exists()).toBeFalsy()
})

it('renders unassigned permissions if any are present', () => {
  const props = makeDefaultProps()
  props.assignedPermissions = []
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('RoleTrayTable')
  expect(node.exists()).toBeTruthy()
  expect(node.props().title).toEqual('Unassigned Permissions')
})

it('renders assigned to', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-assigned-to')
  expect(node.exists()).toBeTruthy()
  expect(node.dive('Text').text()).toEqual('Assigned to: 365')
})

it('renders basedOn if it is set', () => {
  const props = makeDefaultProps()
  props.basedOn = 'Teacher'
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-based-on')
  expect(node.exists()).toBeTruthy()
  expect(node.dive('Text').text()).toEqual('Based on: Teacher')
})

it('does not render basedOn if it is not set', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-based-on')
  expect(node.exists()).toBeFalsy()
})

it('renders changedBy', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-changed-by')
  expect(node.exists()).toBeTruthy()
  expect(node.dive('Text').text()).toEqual('Changed by: Bob Dobbs')
})

it('renders delete icon if deletable is true', () => {
  const props = makeDefaultProps()
  props.deletable = true
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconTrash')
  expect(node.exists()).toBeTruthy()
})

it('does not render delete icon if deletable is false', () => {
  const props = makeDefaultProps()
  props.deletable = false
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconTrash')
  expect(node.exists()).toBeFalsy()
})

it('updaterole calls updaterolenameandbasetype', () => {
  const props = makeDefaultProps()
  const mockFunction = jest.fn()
  props.updateRoleNameAndBaseType = mockFunction
  const tree = shallow(<RoleTray {...props} />)
  tree.instance().updateRole({target: {value: 'blah'}})
  expect(mockFunction).toHaveBeenCalledWith('1', 'blah', null)
})

it('renders edit icon if editable is true', () => {
  const props = makeDefaultProps()
  props.editable = true
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconEdit')
  expect(node.exists()).toBeTruthy()
})

it('does not render edit icon if editable is false', () => {
  const props = makeDefaultProps()
  props.editable = false
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconEdit')
  expect(node.exists()).toBeFalsy()
})

it('renders the label', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('Heading')
  expect(node.exists()).toBeTruthy()
  expect(
    node
      .dive('Heading')
      .dive('Container')
      .text()
  ).toEqual('Student')
})

it('renders the last changed', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-last-changed')
  expect(node.exists()).toBeTruthy()
  expect(node.dive('Text').text()).toEqual('Last changed: 1/1/1970')
})

it('renders the close button when edit mode is not set', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  expect(tree.find('IconX').exists()).toBeTruthy()
  expect(tree.find('IconArrowStart').exists()).toBeFalsy()
})

it('renders the back button when edit mode is set', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({editTrayVisable: true})
  expect(tree.find('IconX').exists()).toBeFalsy()
  expect(tree.find('IconArrowStart').exists()).toBeTruthy()
})

it('calls props.hideTray() and correctly sets state when hideTray is called', () => {
  const hideTrayMock = jest.fn()
  const props = makeDefaultProps()
  props.hideTray = hideTrayMock

  const tree = shallow(<RoleTray {...props} />)
  tree.setState({
    deleteAlertVisable: true,
    editBaseRoleAlertVisable: true,
    editTrayVisable: true
  })
  tree.instance().hideTray() // components hideTray, not props.hideTray method

  const expectedState = {
    deleteAlertVisable: false,
    editBaseRoleAlertVisable: false,
    editTrayVisable: false
  }
  expect(tree.state()).toEqual(expectedState)
  expect(hideTrayMock).toHaveBeenCalled()
})

it('renders the delete confirmation alert if deleteAlertVisable state is true', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({deleteAlertVisable: true})
  const node = tree.find('.role-tray-delete-alert-confirm')
  expect(node.exists()).toBeTruthy()
})

it('does not render the delete confirmation alert if deleteAlertVisable state is false', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-delete-alert-confirm')
  expect(node.exists()).toBeFalsy()
})

it('renders the edit confirmation alert if editBaseRoleAlertVisable state is true', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({editBaseRoleAlertVisable: true})
  const node = tree.find('.role-tray-edit-base-role-confirm')
  expect(node.exists()).toBeTruthy()
})

it('does not render the edit confirmation alert if editBaseRoleAlertVisable state is false', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-edit-base-role-confirm')
  expect(node.exists()).toBeFalsy()
})
