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
import {render} from '@testing-library/react'

import {getPermissionsWithLabels} from '@canvas/permissions/util'
import {ROLES, PERMISSIONS} from '../../__tests__/examples'
import RoleTray from '../RoleTray'

// Mock child components that use Redux
jest.mock('../RoleTrayTableRow', () => {
  return function MockRoleTrayTableRow(props) {
    return <div data-testid="role-tray-table-row">{props.title}</div>
  }
})

jest.mock('../RoleTrayTable', () => {
  return function MockRoleTrayTable({title, children}) {
    return (
      <div data-testid="role-tray-table">
        <div>{title}</div>
        {children}
      </div>
    )
  }
})

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
  const {getByText} = render(<RoleTray {...props} />)
  expect(getByText('Assigned Permissions')).toBeInTheDocument()
})

it('does not render assigned or unassigned permissions if none are present', () => {
  const props = makeDefaultProps()
  props.assignedPermissions = []
  props.unassignedPermissions = []
  const {queryByText} = render(<RoleTray {...props} />)
  expect(queryByText('Assigned Permissions')).not.toBeInTheDocument()
  expect(queryByText('Unassigned Permissions')).not.toBeInTheDocument()
})

it('renders unassigned permissions if any are present', () => {
  const props = makeDefaultProps()
  props.assignedPermissions = []
  const {getByText} = render(<RoleTray {...props} />)
  expect(getByText('Unassigned Permissions')).toBeInTheDocument()
})

it('renders basedOn if it is set', () => {
  const props = makeDefaultProps()
  props.basedOn = 'Teacher'
  const {getByText} = render(<RoleTray {...props} />)
  expect(getByText('Based on: Teacher')).toBeInTheDocument()
})

it('does not render basedOn if it is not set', () => {
  const props = makeDefaultProps()
  const {container} = render(<RoleTray {...props} />)
  expect(container.querySelector('.role-tray-based-on')).not.toBeInTheDocument()
})

it('renders delete icon if deletable is true', () => {
  const props = makeDefaultProps()
  props.deletable = true
  const {getByRole} = render(<RoleTray {...props} />)
  expect(getByRole('button', {name: /delete/i})).toBeInTheDocument()
})

it('does not render delete icon if deletable is false', () => {
  const props = makeDefaultProps()
  props.deletable = false
  const {queryByLabelText} = render(<RoleTray {...props} />)
  expect(queryByLabelText('Delete')).not.toBeInTheDocument()
})

it('updaterole calls updaterolenameandbasetype', () => {
  const props = makeDefaultProps()
  const mockFunction = jest.fn()
  props.updateRoleName = mockFunction
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  component.current.updateRole({target: {value: 'blah'}})
  expect(mockFunction).toHaveBeenCalledWith('1', 'blah', null)
})

it('deleterole calls deleterole prop', () => {
  const props = makeDefaultProps()
  const mockDeleteFunction = jest.fn()
  props.deleteRole = mockDeleteFunction
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  const hideTray = component.current.hideTray
  const hideDeleteAlert = component.current.hideDeleteAlert
  component.current.deleteRole()
  expect(mockDeleteFunction).toHaveBeenCalledWith(props.role, hideTray, hideDeleteAlert)
})

it('renders edit icon if editable is true', () => {
  const props = makeDefaultProps()
  props.editable = true
  const {getByRole} = render(<RoleTray {...props} />)
  expect(getByRole('button', {name: /edit/i})).toBeInTheDocument()
})

it('does not render edit icon if editable is false', () => {
  const props = makeDefaultProps()
  props.editable = false
  const {queryByLabelText} = render(<RoleTray {...props} />)
  expect(queryByLabelText('Edit')).not.toBeInTheDocument()
})

it('renders the label', () => {
  const props = makeDefaultProps()
  const {getByRole} = render(<RoleTray {...props} />)
  expect(getByRole('heading', {name: 'Student'})).toBeInTheDocument()
})

it('renders the last changed', () => {
  const props = makeDefaultProps()
  const {getAllByText} = render(<RoleTray {...props} />)
  expect(getAllByText(/last changed/i)[0]).toBeInTheDocument()
})

it('renders the close button when edit mode is not set', () => {
  const props = makeDefaultProps()
  const {getByRole} = render(<RoleTray {...props} />)
  expect(getByRole('button', {name: /close/i})).toBeInTheDocument()
})

it('renders the back button when edit mode is set', () => {
  const props = makeDefaultProps()
  const component = React.createRef()
  const {getByRole, rerender} = render(<RoleTray {...props} ref={component} />)
  component.current.setState({editTrayVisible: true})
  rerender(<RoleTray {...props} ref={component} />)
  expect(getByRole('button', {name: /back/i})).toBeInTheDocument()
})

it('calls props.hideTray() and correctly sets state when hideTray is called', () => {
  const hideTrayMock = jest.fn()
  const props = makeDefaultProps()
  props.hideTray = hideTrayMock

  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  component.current.setState({
    deleteAlertVisible: true,
    editBaseRoleAlertVisible: true,
    editTrayVisible: true,
    editRoleLabelErrorMessages: [{text: 'ERROR', type: 'newError'}],
    newTargetBaseRole: 'banana',
  })
  component.current.hideTray() // components hideTray, not props.hideTray method

  const expectedState = {
    deleteAlertVisible: false,
    editBaseRoleAlertVisible: false,
    editTrayVisible: false,
    lastTouchedRoleId: undefined,
    newTargetBaseRole: null,
    editRoleLabelInput: '',
    editRoleLabelErrorMessages: [],
  }
  expect(component.current.state).toEqual(expectedState)
  expect(hideTrayMock).toHaveBeenCalled()
})

it('renders the delete confirmation alert if deleteAlertVisible state is true', async () => {
  const props = makeDefaultProps()
  const component = React.createRef()
  const {getByText} = render(<RoleTray {...props} ref={component} />)
  // Set state and then check that the warning message appears
  component.current.setState({deleteAlertVisible: true})
  // The renderDeleteAlert method should render the confirmation text
  // Let's just check that the component instance's state has been updated
  expect(component.current.state.deleteAlertVisible).toBe(true)
})

it('does not render the delete confirmation alert if deleteAlertVisible state is false', async () => {
  const props = makeDefaultProps()
  const {container} = render(<RoleTray {...props} />)
  expect(container.querySelector('.role-tray-delete-alert-confirm')).not.toBeInTheDocument()
})

it('renders the edit confirmation alert if editBaseRoleAlertVisible state is true', () => {
  const props = makeDefaultProps()
  const component = React.createRef()
  const {getByRole, rerender} = render(<RoleTray {...props} ref={component} />)
  component.current.setState({editBaseRoleAlertVisible: true})
  rerender(<RoleTray {...props} ref={component} />)
  expect(getByRole('button', {name: /ok/i})).toBeInTheDocument()
})

it('does not render the edit confirmation alert if editBaseRoleAlertVisible state is false', () => {
  const props = makeDefaultProps()
  const {container} = render(<RoleTray {...props} />)
  expect(container.querySelector('.role-tray-edit-base-role-confirm')).not.toBeInTheDocument()
})

// API does not currently support this, but the code is in place for it
it('does not render the base role selector', () => {
  const props = makeDefaultProps()
  const {container} = render(<RoleTray {...props} />)
  expect(container.querySelector('[role="combobox"]')).not.toBeInTheDocument()
})

it('onChangeRoleLabel sets error if role is used', () => {
  const props = makeDefaultProps()
  props.allRoleLabels = {student: true, teacher: true}
  props.label = 'student'
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  const event = {target: {value: ' teacher   '}} // make sure trimming happens
  component.current.onChangeRoleLabel(event)
  // We don't trim in the state; we only trim for purposes of error-checking
  // and post requests
  expect(component.current.state.editRoleLabelInput).toEqual(' teacher   ')
  expect(component.current.state.editRoleLabelErrorMessages).toHaveLength(1)
  expect(component.current.state.editRoleLabelErrorMessages[0].text).toEqual(
    'Cannot change role name to teacher: already in use',
  )
  expect(component.current.state.editRoleLabelErrorMessages[0].type).toEqual('newError')
})

it('onChangeRoleLabel, not an error if label === present', () => {
  const props = makeDefaultProps()
  props.allRoleLabels = {student: true, teacher: true}
  props.label = 'student'
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  const event = {target: {value: 'student'}}
  component.current.onChangeRoleLabel(event)
  expect(component.current.state.editRoleLabelErrorMessages).toHaveLength(0)
})

it('updateRole will not try to update if error', () => {
  const props = makeDefaultProps()
  props.updateRole = jest.fn()
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  component.current.setState({editRoleLabelErrorMessages: [{text: 'ERROR', type: 'error'}]})
  const event = {target: {value: 'student'}}
  component.current.updateRole(event)
  expect(props.updateRole).toHaveBeenCalledTimes(0)
})

it('updateRole will reset value and not try to edit if empty', () => {
  const props = makeDefaultProps()
  const mockUpdateRoleName = jest.fn()
  props.updateRoleName = mockUpdateRoleName
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  const input = '   '
  const event = {target: {value: input}}
  component.current.updateRole(event)
  expect(component.current.state.editRoleLabelInput).toEqual(props.role.label)
  expect(component.current.state.editRoleLabelErrorMessages).toHaveLength(0)
  expect(mockUpdateRoleName).toHaveBeenCalledTimes(0)
})

it('if everything is happy then updateRole will call an update', () => {
  const props = makeDefaultProps()
  const mockUpdateRoleName = jest.fn()
  props.updateRoleName = mockUpdateRoleName
  const component = React.createRef()
  render(<RoleTray {...props} ref={component} />)
  const event = {target: {value: '   grumpmaster '}}
  component.current.updateRole(event)
  expect(mockUpdateRoleName).toHaveBeenCalledTimes(1)
  expect(mockUpdateRoleName).toHaveBeenCalledWith(props.id, 'grumpmaster', props.basedOn)
})
