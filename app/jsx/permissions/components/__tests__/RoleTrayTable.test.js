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
import {mount} from 'enzyme'

import RoleTrayTable from '../RoleTrayTable'
import RoleTrayTableRow from '../RoleTrayTableRow'

it('renders the component with only one child', () => {
  const tree = mount(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow title="banana" />
    </RoleTrayTable>
  )
  const rootNode = tree.find('RoleTrayTable')
  const childrenNodes = tree.find('RoleTrayTableRow')
  expect(rootNode.exists()).toBeTruthy()
  expect(childrenNodes).toHaveLength(1)
})

it('renders the component with multiple children', () => {
  const tree = mount(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow title="banana" />
      <RoleTrayTableRow title="apple" />
      <RoleTrayTableRow title="mango" />
    </RoleTrayTable>
  )
  const node = tree.find('RoleTrayTable')
  const childrenNodes = tree.find('RoleTrayTableRow')
  expect(node.exists()).toBeTruthy()
  expect(childrenNodes).toHaveLength(3)
})

it('renders the title', () => {
  const tree = mount(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow title="banana" />
    </RoleTrayTable>
  )
  const node = tree.find('Text')
  expect(node.at(0).text()).toEqual('fruit')
})

it('sorts the children by title', () => {
  const tree = mount(
    <RoleTrayTable title="fruit">
      <RoleTrayTableRow title="banana" />
      <RoleTrayTableRow title="apple" />
      <RoleTrayTableRow title="mango" />
    </RoleTrayTable>
  )
  const nodes = tree.find('Text')
  expect(nodes.at(1).text()).toEqual('apple')
  expect(nodes.at(2).text()).toEqual('banana')
  expect(nodes.at(3).text()).toEqual('mango')
})
