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

import AddTray, {mapStateToProps} from 'jsx/permissions/components/AddTray'

const defaultProps = () => ({
  permissions: [
    {permission_name: 'account_permission', label: 'account_permission', displayed: true},
    {permission_name: 'course_permission', label: 'course_permission', displayed: true}
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
          enabled: true,
          explicit: false,
          locked: false,
          readonly: false
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: false,
          explicit: false,
          locked: false,
          readonly: false
        }
      }
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
          enabled: true,
          explicit: false,
          locked: false,
          readonly: false
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: false,
          explicit: false,
          locked: false,
          readonly: false
        }
      }
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
          enabled: true,
          explicit: false,
          locked: false,
          readonly: false
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: false,
          explicit: false,
          locked: false,
          readonly: false
        }
      }
    },
    {
      id: '6',
      role: 'DesignerEnrollment',
      label: 'Course Designer',
      base_role_type: 'DesignerEnrollment',
      workflow_state: 'built_in',
      permissions: {
        account_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: true,
          explicit: false,
          locked: false,
          readonly: false
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: false,
          explicit: false,
          locked: false,
          readonly: false
        }
      }
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
          enabled: true,
          explicit: false,
          locked: false,
          readonly: false
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: false,
          explicit: false,
          locked: false,
          readonly: false
        }
      }
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
          enabled: true,
          explicit: false,
          locked: false,
          readonly: false
        },
        course_permission: {
          applies_to_descendants: true,
          applies_to_self: true,
          enabled: false,
          explicit: false,
          locked: false,
          readonly: false
        }
      }
    }
  ]
})

it('renders proper loading state for component', () => {
  const props = defaultProps()
  props.loading = true
  const tree = shallow(<AddTray {...props} />)
  const node = tree.find('Spinner')
  expect(node.exists()).toBeTruthy()
})

it('onChangeRoleName changes role name properly', () => {
  const props = defaultProps()
  const tree = shallow(<AddTray {...props} />)
  const inst = tree.instance()
  inst.onChangeRoleName({
    target: {
      value: 'Awesome_aaron'
    }
  })
  expect(tree.state().selectedRoleName).toEqual('Awesome_aaron')
})

it('save button is properly disabled if no role name is set', () => {
  const props = defaultProps()
  const tree = shallow(<AddTray {...props} />)
  tree.setState({
    selectedRoleName: ''
  })
  const inst = tree.instance()
  expect(inst.isDoneSelecting()).toBeFalsy()
})

it('save button is properly enabled if role name is set', () => {
  const props = defaultProps()
  const tree = shallow(<AddTray {...props} />)
  tree.setState({
    selectedRoleName: 'blahp'
  })
  const inst = tree.instance()
  expect(inst.isDoneSelecting()).toBeTruthy()
})

it('does not pass in the account admin base role in mapStateToProps', () => {
  const ownProps = {}
  const state = {
    activeAddTray: {
      show: true,
      loading: false
    },
    roles: [
      {
        id: '1',
        base_role_type: 'StudentEnrollment',
        label: 'Student',
        role: 'StudentEnrollment',
        displayed: true,
        contextType: 'Course'
      },
      {
        id: '2',
        base_role_type: 'AccountMembership',
        label: 'Account Admin',
        role: 'AccountAdmin',
        displayed: false,
        contextType: 'Account'
      }
    ]
  }

  const realProps = mapStateToProps(state, ownProps)
  expect(realProps.allBaseRoles).toEqual([state.roles[0]])
})

it('onChangeRoleLabel sets error if role is used', () => {
  const props = defaultProps()
  props.allLabels = ['student', 'teacher']
  const tree = shallow(<AddTray {...props} />)
  const event = {target: {value: ' teacher   '}} // make sure trimming happens
  tree.instance().onChangeRoleName(event)
  const expectedErrorState = [
    {
      text: 'Cannot add role name teacher: already in use',
      type: 'error'
    }
  ]
  expect(tree.state().roleNameErrors).toEqual(expectedErrorState)
})
