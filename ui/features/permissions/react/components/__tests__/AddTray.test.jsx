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
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import AddTray, {mapStateToProps} from '../AddTray'
import {ENABLED_FOR_ALL, ENABLED_FOR_NONE} from '@canvas/permissions/react/propTypes'

const defaultProps = () => ({
  permissions: [
    {permission_name: 'account_permission', label: 'account_permission', displayed: true},
    {permission_name: 'course_permission', label: 'course_permission', displayed: true},
  ],
  createNewRole: () => {},
  loading: false,
  hideTray: () => {},
  open: true,
  tab: 'course',
  allLabels: [],
  allBaseRoles: [
    {
      id: '3',
      role: 'StudentEnrollment',
      label: 'Student',
      base_role_type: 'StudentEnrollment',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_ALL,
          explicit: false,
          locked: false,
          readonly: false,
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_NONE,
          explicit: false,
          locked: false,
          readonly: false,
        },
      },
    },
    {
      id: '4',
      role: 'TeacherEnrollment',
      label: 'Teacher',
      base_role_type: 'TeacherEnrollment',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_ALL,
          explicit: false,
          locked: false,
          readonly: false,
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_NONE,
          explicit: false,
          locked: false,
          readonly: false,
        },
      },
    },
    {
      id: '5',
      role: 'TaEnrollment',
      label: 'TA',
      base_role_type: 'TaEnrollment',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_ALL,
          explicit: false,
          locked: false,
          readonly: false,
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_NONE,
          explicit: false,
          locked: false,
          readonly: false,
        },
      },
    },
    {
      id: '6',
      role: 'DesignerEnrollment',
      label: 'Designer',
      base_role_type: 'DesignerEnrollment',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_ALL,
          explicit: false,
          locked: false,
          readonly: false,
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_NONE,
          explicit: false,
          locked: false,
          readonly: false,
        },
      },
    },
    {
      id: '7',
      role: 'ObserverEnrollment',
      label: 'Observer',
      base_role_type: 'ObserverEnrollment',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_ALL,
          explicit: false,
          locked: false,
          readonly: false,
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_NONE,
          explicit: false,
          locked: false,
          readonly: false,
        },
      },
    },
    {
      id: '1',
      role: 'AccountAdmin',
      label: 'Account admin',
      base_role_type: 'AccountMembership',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_ALL,
          explicit: false,
          locked: false,
          readonly: false,
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: ENABLED_FOR_NONE,
          explicit: false,
          locked: false,
          readonly: false,
        },
      },
    },
  ],
})

it('renders proper loading state for component', () => {
  const props = defaultProps()
  props.loading = true
  const {getByText} = render(<AddTray {...props} />)
  expect(getByText('Saving New Role')).toBeInTheDocument()
})

it('changes role name when user types in input', async () => {
  const props = defaultProps()
  const {getByLabelText} = render(<AddTray {...props} />)

  const roleNameInput = getByLabelText('Role Name *')
  fireEvent.change(roleNameInput, {target: {value: 'Awesome_aaron'}})

  expect(roleNameInput).toHaveValue('Awesome_aaron')
})

it('displays an error if attempting to save with an empty role name', async () => {
  const props = defaultProps()
  render(<AddTray {...props} />)
  const save = screen.getByText('Save')

  fireEvent.click(save)

  const errorText = await screen.findByText('A role name is required')
  expect(errorText).toBeInTheDocument()
})

it('clears the empty role name error when text is entered', async () => {
  const props = defaultProps()
  render(<AddTray {...props} />)
  const save = screen.getByText('Save')
  const roleNameInput = screen.getByLabelText('Role Name *')

  fireEvent.click(save)

  let errorText = await screen.findByText('A role name is required')
  expect(errorText).toBeInTheDocument()

  fireEvent.input(roleNameInput, {target: {value: 'Custom Student Role'}})

  errorText = screen.queryByText('A role name is required')
  expect(errorText).not.toBeInTheDocument()
})

it('does not pass in the account admin base role in mapStateToProps', () => {
  const ownProps = {}
  const state = {
    activeAddTray: {
      show: true,
      loading: false,
    },
    roles: [
      {
        id: '1',
        base_role_type: 'StudentEnrollment',
        label: 'Student',
        role: 'StudentEnrollment',
        displayed: true,
        contextType: 'Course',
      },
      {
        id: '2',
        base_role_type: 'AccountMembership',
        label: 'Account Admin',
        role: 'AccountAdmin',
        displayed: false,
        contextType: 'Account',
      },
    ],
  }

  const realProps = mapStateToProps(state, ownProps)
  expect(realProps.allBaseRoles).toEqual([state.roles[0]])
})

it('shows error when role name is already in use', async () => {
  const user = userEvent.setup()
  const props = defaultProps()
  props.allLabels = ['student', 'teacher']
  const {getByLabelText} = render(<AddTray {...props} />)

  const roleNameInput = getByLabelText('Role Name *')
  await user.clear(roleNameInput)
  await user.type(roleNameInput, 'teacher')

  // InstUI TextInput renders error messages differently, so we need to check for aria-invalid
  expect(roleNameInput).toHaveAttribute('aria-invalid', 'true')
})
