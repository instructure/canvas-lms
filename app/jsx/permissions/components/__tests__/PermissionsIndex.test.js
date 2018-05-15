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
import {Provider} from 'react-redux'
import {mount} from 'enzyme'

import {COURSE} from '../../propTypes'
import PermissionsIndex from '../PermissionsIndex'

const defaultProps = () => ({
  contextId: 1,
  permissions: [],
  roles: [],
  searchPermissions: () => {}
})

const permissions = [
  {
    permission_name: 'add_section',
    label: 'add section',
    contextType: COURSE,
    displayed: true
  },
  {
    permission_name: 'delete_section',
    label: 'delete section',
    contextType: COURSE,
    displayed: true
  }
]

const store = {
  getState: () => ({
    activeRoleTray: null,
    contextId: 1,
    permissions,
    roles: []
  }),
  dispatch() {},
  subscribe() {}
}

it('renders the component', () => {
  const tree = mount(
    <Provider store={store}>
      <PermissionsIndex {...defaultProps()} />
    </Provider>
  )
  const node = tree.find('PermissionsIndex')
  expect(node.exists()).toEqual(true)
})

// TODO: Figure out how to test debounce in jest
