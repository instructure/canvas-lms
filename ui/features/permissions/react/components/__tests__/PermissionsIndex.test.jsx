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
import {fireEvent, render} from '@testing-library/react'
import {Provider} from 'react-redux'
import {COURSE, ACCOUNT} from '@canvas/permissions/react/propTypes'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

import {DEFAULT_PROPS} from '../../__tests__/examples'
import {ConnectedPermissionsIndex as Subject} from '../PermissionsIndex'
import createStore from '../../store'

injectGlobalAlertContainers()

function renderWithRedux(subject, {data, store = createStore(data), ...renderOptions} = {}) {
  const Wrapper = props => <Provider store={store}>{props.children}</Provider>

  return render(subject, {wrapper: Wrapper, ...renderOptions})
}

it('displays course roles initially', () => {
  const data = DEFAULT_PROPS()
  const {getAllByText, queryByText} = renderWithRedux(<Subject />, {data})
  data.roles.forEach(role => {
    if (role.contextType === COURSE) expect(getAllByText(role.label)).toHaveLength(1)
    if (role.contextType === ACCOUNT) expect(queryByText(role.label)).toBeNull()
  })
})

it('switches to account roles when tab is clicked on', () => {
  const data = DEFAULT_PROPS()
  const {getAllByText, getByText, queryByText} = renderWithRedux(<Subject />, {data})
  fireEvent.click(getByText('Account Roles'))
  data.roles.forEach(role => {
    if (role.contextType === ACCOUNT) expect(getAllByText(role.label)).toHaveLength(1)
    if (role.contextType === COURSE) expect(queryByText(role.label)).toBeNull()
  })
})

it('switches back to course roles tab with proper context from account roles tab', () => {
  const data = DEFAULT_PROPS()
  const {getAllByText, getByText, queryByText} = renderWithRedux(<Subject />, {data})
  fireEvent.click(getByText('Account Roles'))
  fireEvent.click(getByText('Course Roles'))
  data.roles.forEach(role => {
    if (role.contextType === ACCOUNT) expect(queryByText(role.label)).toBeNull()
    if (role.contextType === COURSE) expect(getAllByText(role.label)).toHaveLength(1)
  })
})

it('filters roles properly', () => {
  const data = DEFAULT_PROPS()
  const roleSelect = data.roles.filter(role => role.contextType === COURSE)[0]
  const {getAllByText, container, queryByText} = renderWithRedux(<Subject />, {data})
  const multiSelect = container.querySelector('#permissions-role-filter')
  fireEvent.input(multiSelect, {target: {value: roleSelect.label}})
  fireEvent.blur(multiSelect)
  data.roles.forEach(role => {
    if (role.id === roleSelect.id) {
      expect(getAllByText(role.label)).toHaveLength(2)
    } else {
      expect(queryByText(role.label)).toBeNull()
    }
  })
})
