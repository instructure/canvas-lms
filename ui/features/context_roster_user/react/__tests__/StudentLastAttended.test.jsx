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

import '@instructure/canvas-theme'
import React from 'react'
import {mount, shallow} from 'enzyme'
import StudentLastAttended from '../StudentLastAttended'

const defaultProps = () => ({
  defaultDate: '2018-03-04T07:00:00.000Z',
  courseID: '1',
  studentID: '1',
})

test('renders the StudentLastAttended component', () => {
  const tree = mount(<StudentLastAttended {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('renders loading component when loading', () => {
  const tree = shallow(<StudentLastAttended {...defaultProps()} />)
  tree.setState({loading: true})
  const node = tree.find('Spinner')
  expect(node).toHaveLength(1)
})

test('onDateSubmit calls correct function', () => {
  const tree = mount(<StudentLastAttended {...defaultProps()} />)
  const node = tree.find('Text').at(0)
  expect(node.text()).toBe('Last day attended')
})
