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

import {DEFAULT_PROPS} from '../../__tests__/examples'
import PermissionsIndex from '../PermissionsIndex'

it('sets selected roles correctly when there are no roles selected', () => {
  const tree = shallow(<PermissionsIndex {...DEFAULT_PROPS()} />)
  tree.instance().onAutocompleteBlur({target: {value: ''}})
  expect(tree.instance().props.selectedRoles[0].value).toEqual('0')
})

it('correctly calls the filter roles function', () => {
  const mockFilterRoles = jest.fn()
  const newDefault = DEFAULT_PROPS()
  newDefault.filterRoles = mockFilterRoles

  const expectedDispatch = {contextType: 'Course', selectedRoles: [{value: '1', label: 'stuff'}]}

  const tree = shallow(<PermissionsIndex {...newDefault} />)
  tree
    .instance()
    .onRoleFilterChange(null, [{value: '1', label: 'stuff'}, {value: '0', label: 'All Roles'}])
  expect(mockFilterRoles).toHaveBeenCalledTimes(1)
  expect(mockFilterRoles).toHaveBeenCalledWith(expectedDispatch)
})

it('sets selected roles correctly when we are changing tabs', () => {
  const tree = shallow(<PermissionsIndex {...DEFAULT_PROPS()} />)
  tree.instance().onTabChanged(0, 1)
  expect(tree.instance().props.selectedRoles[0].value).toEqual('0')
  // Select something and change tabs to make sure we clear the selection out
  tree.instance().onRoleFilterChange(null, [{value: '1', label: 'stuff'}])
  tree.instance().onTabChanged(1, 0)
  expect(tree.instance().props.selectedRoles[0].value).toEqual('0')
})
