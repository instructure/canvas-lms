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
import {Provider} from 'react-redux'

import {ROLES, DEFAULT_PROPS} from '../../__tests__/examples'
import PermissionTray from '../PermissionTray'
import {ENABLED_FOR_ALL} from '@canvas/permissions/react/propTypes'
import createStore from '../../store'

const permission = {
  enabled: ENABLED_FOR_ALL,
  locked: false,
  readonly: false,
  explicit: true,
}

function makeDefaultProps() {
  return {
    assignedRoles: ROLES.filter(r => r.id === '1'),
    label: 'Student',
    permissionName: 'add_section',
    permission,
    tab: 'account',
    open: true,
    hideTray: Function.prototype,
    modifyPermissions: Function.prototype,
    unassignedRoles: ROLES.filter(r => r.id === '2'),
  }
}

function renderWithRedux(
  subject,
  {data = DEFAULT_PROPS(), store = createStore(data), ...renderOptions} = {},
) {
  const Wrapper = props => <Provider store={store}>{props.children}</Provider>
  return render(subject, {wrapper: Wrapper, ...renderOptions})
}

it('renders the label', () => {
  const props = makeDefaultProps()
  const {getByRole} = renderWithRedux(<PermissionTray {...props} />)
  const heading = getByRole('heading', {name: 'Student'})
  expect(heading).toBeInTheDocument()
})

it('renders assigned roles if any are present', () => {
  const props = makeDefaultProps()
  props.unassignedRoles = []
  const {getByText} = renderWithRedux(<PermissionTray {...props} />)
  expect(getByText('Assigned Roles')).toBeInTheDocument()
})

it('does not render assigned or unassigned roles if none are present', () => {
  const props = makeDefaultProps()
  props.assignedRoles = []
  props.unassignedRoles = []
  const {queryByText} = renderWithRedux(<PermissionTray {...props} />)
  expect(queryByText('Assigned Roles')).not.toBeInTheDocument()
  expect(queryByText('Unassigned Roles')).not.toBeInTheDocument()
})

it('renders unassigned roles if any are present', () => {
  const props = makeDefaultProps()
  props.assignedRoles = []
  const {getByText} = renderWithRedux(<PermissionTray {...props} />)
  expect(getByText('Unassigned Roles')).toBeInTheDocument()
})

it('renders details toggles for permissions if any are present', () => {
  const props = makeDefaultProps()
  const {getByTitle} = renderWithRedux(<PermissionTray {...props} />)
  expect(getByTitle('Loading')).toBeInTheDocument()
})
