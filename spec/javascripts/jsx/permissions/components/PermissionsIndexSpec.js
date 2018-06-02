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
import { mount, shallow } from 'enzyme'

import PermissionsIndex from 'jsx/permissions/components/PermissionsIndex'

const defaultProps = () => ({
  permissions: [],
  contextId: 1,
  isLoadingPermissions: false,
  hasLoadedPermissions: false,
  getPermissions: ()=> {}
})

QUnit.module('PermissionsIndex component')

test('renders the component', () => {
  const tree = mount(<PermissionsIndex {...defaultProps()} />)
  const node = tree.find('PermissionsIndex')
  ok(node.exists())
})

test('displays spinner when loading permissions', () => {
  const props = defaultProps()
  props.isLoadingPermissions = true
  const tree = shallow(<PermissionsIndex {...props} />)
  const node = tree.find('Spinner')
  ok(node.exists())
})

test('calls getPermissions if hasLoadedPermissions is false', () => {
  const props = defaultProps()
  props.getPermissions = sinon.spy()
  mount(<PermissionsIndex {...props} />)
  equal(props.getPermissions.callCount, 1)
})
