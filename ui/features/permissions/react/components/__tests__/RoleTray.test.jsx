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

import {getPermissionsWithLabels} from '@canvas/permissions/util'
import {ROLES, PERMISSIONS} from '../../__tests__/examples'
import RoleTray from '../RoleTray'

function makeDefaultProps() {
  const role = ROLES[0]
  const perms = getPermissionsWithLabels(PERMISSIONS, role.permissions)
  return {
    assignedPermissions: perms,
    id: '1',
    basedOn: null,
    updateRoleName: () => {},
    baseRoleLabels: ['Student', 'Teacher', 'TA'],
    deleteRole: () => {},
    deletable: false,
    editable: false,
    hideTray: () => {},
    label: 'Student',
    lastChanged: '1/1/1970',
    open: true,
    role,
    unassignedPermissions: perms,
  }
}

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

it('renders basedOn if it is set', () => {
  const props = makeDefaultProps()
  props.basedOn = 'Teacher'
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-based-on')
  expect(node.exists()).toBeTruthy()
  expect(node.children().text()).toEqual('Based on: Teacher')
})

it('does not render basedOn if it is not set', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-based-on')
  expect(node.exists()).toBeFalsy()
})

it('renders delete icon if deletable is true', () => {
  const props = makeDefaultProps()
  props.deletable = true
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconTrashLine')
  expect(node.exists()).toBeTruthy()
})

it('does not render delete icon if deletable is false', () => {
  const props = makeDefaultProps()
  props.deletable = false
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconTrashLine')
  expect(node.exists()).toBeFalsy()
})

it('updaterole calls updaterolenameandbasetype', () => {
  const props = makeDefaultProps()
  const mockFunction = jest.fn()
  props.updateRoleName = mockFunction
  const tree = shallow(<RoleTray {...props} />)
  tree.instance().updateRole({target: {value: 'blah'}})
  expect(mockFunction).toHaveBeenCalledWith('1', 'blah', null)
})

it('deleterole calls deleterole prop', () => {
  const props = makeDefaultProps()
  const mockDeleteFunction = jest.fn()
  props.deleteRole = mockDeleteFunction
  const tree = shallow(<RoleTray {...props} />)
  const hideTray = tree.instance().hideTray
  const hideDeleteAlert = tree.instance().hideDeleteAlert
  tree.instance().deleteRole()
  expect(mockDeleteFunction).toHaveBeenCalledWith(props.role, hideTray, hideDeleteAlert)
})

it('renders edit icon if editable is true', () => {
  const props = makeDefaultProps()
  props.editable = true
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconEditLine')
  expect(node.exists()).toBeTruthy()
})

it('does not render edit icon if editable is false', () => {
  const props = makeDefaultProps()
  props.editable = false
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('IconEditLine')
  expect(node.exists()).toBeFalsy()
})

it('renders the label', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('Heading')
  expect(node.exists()).toBeTruthy()
  expect(node.children().text()).toEqual('Student')
})

it('renders the last changed', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('.role-tray-last-changed')
  expect(node.exists()).toBeTruthy()
})

it('renders the close button when edit mode is not set', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  expect(tree.find('IconXSolid').exists()).toBeTruthy()
  expect(tree.find('IconArrowStartSolid').exists()).toBeFalsy()
})

it('renders the back button when edit mode is set', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({editTrayVisible: true})
  expect(tree.find('IconXSolid').exists()).toBeFalsy()
  expect(tree.find('IconArrowStartSolid').exists()).toBeTruthy()
})

it('calls props.hideTray() and correctly sets state when hideTray is called', () => {
  const hideTrayMock = jest.fn()
  const props = makeDefaultProps()
  props.hideTray = hideTrayMock

  const tree = shallow(<RoleTray {...props} />)
  tree.setState({
    deleteAlertVisible: true,
    editBaseRoleAlertVisible: true,
    editTrayVisible: true,
    editRoleLabelErrorMessages: [{text: 'ERROR', type: 'error'}],
    newTargetBaseRole: 'banana',
  })
  tree.instance().hideTray() // components hideTray, not props.hideTray method

  const expectedState = {
    deleteAlertVisible: false,
    editBaseRoleAlertVisible: false,
    editTrayVisible: false,
    lastTouchedRoleId: undefined,
    newTargetBaseRole: null,
    editRoleLabelInput: '',
    editRoleLabelErrorMessages: [],
  }
  expect(tree.state()).toEqual(expectedState)
  expect(hideTrayMock).toHaveBeenCalled()
})

it('renders the delete confirmation alert if deleteAlertVisible state is true', async () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({deleteAlertVisible: true})
  const node = tree.findWhere(
    n => n.name() === 'Dialog' && n.children('.role-tray-delete-alert-confirm')
  )
  expect(node.at(0).props().open).toBe(true)
})

it('does not render the delete confirmation alert if deleteAlertVisible state is false', async () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.findWhere(
    n => n.name() === 'Dialog' && n.children('.role-tray-delete-alert-confirm')
  )
  expect(node.at(0).props().open).toBe(false)
})

it('renders the edit confirmation alert if editBaseRoleAlertVisible state is true', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({editBaseRoleAlertVisible: true})
  const node = tree.findWhere(
    n => n.name() === 'Dialog' && n.children('.role-tray-edit-base-role-confirm')
  )
  expect(node.at(0).props().open).toBe(false)
})

it('does not render the edit confirmation alert if editBaseRoleAlertVisible state is false', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.findWhere(
    n => n.name() === 'Dialog' && n.children('.role-tray-edit-base-role-confirm')
  )
  expect(node.at(0).props().open).toBe(false)
})

// API does not currently support this, but the code is in place for it
it('does not render the base role selector', () => {
  const props = makeDefaultProps()
  const tree = shallow(<RoleTray {...props} />)
  const node = tree.find('Select')
  expect(node.exists()).toBeFalsy()
})

it('onChangeRoleLabel sets error if role is used', () => {
  const props = makeDefaultProps()
  props.allRoleLabels = {student: true, teacher: true}
  props.label = 'student'
  const tree = shallow(<RoleTray {...props} />)
  const event = {target: {value: ' teacher   '}} // make sure trimming happens
  tree.instance().onChangeRoleLabel(event)
  // We don't trim in the state; we only trim for purposes of error-checking
  // and post requests
  expect(tree.state().editRoleLabelInput).toEqual(' teacher   ')
  expect(tree.state().editRoleLabelErrorMessages).toHaveLength(1)
  expect(tree.state().editRoleLabelErrorMessages[0].text).toEqual(
    'Cannot change role name to teacher: already in use'
  )
  expect(tree.state().editRoleLabelErrorMessages[0].type).toEqual('error')
})

it('onChangeRoleLabel, not an error if label === present', () => {
  const props = makeDefaultProps()
  props.allRoleLabels = {student: true, teacher: true}
  props.label = 'student'
  const tree = shallow(<RoleTray {...props} />)
  const event = {target: {value: 'student'}}
  tree.instance().onChangeRoleLabel(event)
  expect(tree.state().editRoleLabelErrorMessages).toHaveLength(0)
})

it('updateRole will not try to update if error', () => {
  const props = makeDefaultProps()
  props.updateRole = jest.fn()
  const tree = shallow(<RoleTray {...props} />)
  tree.setState({editRoleLabelErrorMessage: [{text: 'ERROR', type: 'error'}]})
  const event = {target: {value: 'student'}}
  tree.instance().updateRole(event)
  expect(props.updateRole).toHaveBeenCalledTimes(0)
})

it('updateRole will reset value and not try to edit if empty', () => {
  const props = makeDefaultProps()
  const mockUpdateRoleName = jest.fn()
  props.updateRoleName = mockUpdateRoleName
  const tree = shallow(<RoleTray {...props} />)
  const input = '   '
  const event = {target: {value: input}}
  tree.instance().updateRole(event)
  expect(tree.state().editRoleLabelInput).toEqual(props.role.label)
  expect(tree.state().editRoleLabelErrorMessages).toHaveLength(0)
  expect(mockUpdateRoleName).toHaveBeenCalledTimes(0)
})

it('if everything is happy then updateRole will call an update', () => {
  const props = makeDefaultProps()
  const mockUpdateRoleName = jest.fn()
  props.updateRoleName = mockUpdateRoleName
  const tree = shallow(<RoleTray {...props} />)
  const event = {target: {value: '   grumpmaster '}}
  tree.instance().updateRole(event)
  expect(mockUpdateRoleName).toHaveBeenCalledTimes(1)
  expect(mockUpdateRoleName).toHaveBeenCalledWith(props.id, 'grumpmaster', props.basedOn)
})
