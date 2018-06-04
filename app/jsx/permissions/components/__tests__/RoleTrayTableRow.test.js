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

import RoleTrayTableRow from '../RoleTrayTableRow'

it('renders the component', () => {
  const tree = mount(<RoleTrayTableRow title="banana" />)
  const node = tree.find('RoleTrayTableRow')
  expect(node.exists()).toBeTruthy()
})

it('renders the title', () => {
  const tree = mount(<RoleTrayTableRow title="banana" />)
  const node = tree.find('Text')
  expect(node.exists()).toBeTruthy()
  expect(node.text()).toEqual('banana')
})

it('renders the expandable button if expandable prop is true', () => {
  const tree = mount(<RoleTrayTableRow title="banana" expandable />)
  const node = tree.find('IconArrowOpenStart')
  expect(node.exists()).toBeTruthy()
})

it('does not render the expandable button if expandable prop is false', () => {
  const tree = mount(<RoleTrayTableRow title="banana" />)
  const node = tree.find('IconArrowOpenStart')
  expect(node.exists()).toBeFalsy()
})

it('renders the description if provided', () => {
  const tree = mount(<RoleTrayTableRow title="banana" description="it's a fruit" />)
  const node = tree.find('Text')
  expect(node.at(1).exists()).toBeTruthy()
  expect(node.at(1).text()).toEqual("it's a fruit")
})

it('does not render the description if not provided', () => {
  const tree = mount(<RoleTrayTableRow title="banana" />)
  const node = tree.find('Text')
  expect(node.at(1).exists()).toBeFalsy()
})
